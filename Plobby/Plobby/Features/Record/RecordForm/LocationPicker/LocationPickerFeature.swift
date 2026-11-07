//
//  LocationPickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import CoreLocation

import ComposableArchitecture

@Reducer
struct LocationPickerFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.beaches) var allBeaches
        var screen: Screen = .search
        var query: String = ""
        var searchStatus: SearchStatus = .idle
        var authorization: LocationAuthorization = .notDetermined
        var mapCenter: Coordinate = .fallback    // 지도 가운데(핀) 좌표
        var cameraTarget: CameraTarget = .init(center: .fallback)    // 코드로 지도를 옮길 때만 바뀌어요
        var beachLookup: BeachLookup = .idle    // 핀 근처 해변
        var isBeachSelected: Bool = false    // 해변 카드를 눌러 선택했는지
        var isLocating: Bool = false

        var foundBeach: Beach? {
            guard case let .found(beach) = beachLookup else { return nil }
            
            return beach
        }

        var isSaveEnabled: Bool {
            foundBeach != nil && isBeachSelected
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case authorizationResponse(LocationAuthorization)
        case searchResultTapped(PlaceSearchResult.ID)    // 검색 결과 탭 → 해당 위치로 지도 화면 이동
        case nearbyBeachesTapped    // 주변 해변 보기 탭
        case currentLocationButtonTapped    // 현위치 버튼 탭
        case currentLocationResponse(Result<Coordinate, any Error>)
        case mapCameraChangeEnded(center: Coordinate)    // 사용자가 지도 중심을 옮기기를 완료했을 때 해변 조회
        case beachCardTapped
        case saveTapped
        case backTapped    // 상단 뒤로가기: 지도면 검색으로, 검색이면 기록 양식으로
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case selected(Beach)
        }
    }

    // MARK: - Dependency

    @Dependency(\.locationClient) var locationClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.query):
                guard !InputText.isBlank(state.query) else {
                    state.searchStatus = .idle
                    return .none
                }

                let results = state.allBeaches
                    .matching(state.query)
                    .map(PlaceSearchResult.init(beach:))

                state.searchStatus = results.isEmpty ? .empty : .results(results)
                return .none

            case let .authorizationResponse(authorization):
                state.authorization = authorization
                return .none

            case let .searchResultTapped(resultID):
                guard let beach = state.allBeaches.first(where: { $0.id == resultID }) else {
                    return .none
                }

                state.screen = .map
                moveCamera(to: beach.coordinate, state: &state)
                return .none

            case .nearbyBeachesTapped:
                state.screen = .map
                // 위치 권한이 정해지지 않았다면 현재 위치를 받는 순간 권한 팝업이 떠요. 거부하면 기본 위치를 보여줘요.
                return fetchCurrentLocation(&state)

            case .currentLocationButtonTapped:
                return fetchCurrentLocation(&state)

            case let .currentLocationResponse(.success(coordinate)):
                state.isLocating = false
                state.authorization = .authorized
                moveCamera(to: coordinate, state: &state)
                return .none

            case let .currentLocationResponse(.failure(error)):
                state.isLocating = false

                if (error as? LocationClientError) == .denied {
                    state.authorization = .denied
                    moveCamera(to: .fallback, state: &state)
                    return .none
                }
                
                PlobbyLogger.error(error)
                lookUpBeach(at: state.mapCenter, state: &state)
                return .none

            case let .mapCameraChangeEnded(center):
                state.mapCenter = center
                lookUpBeach(at: center, state: &state)
                return .none

            case .beachCardTapped:
                guard state.foundBeach != nil else { return .none }

                state.isBeachSelected = true
                return .none

            case .saveTapped:
                guard state.isSaveEnabled, let beach = state.foundBeach else { return .none }

                return .send(.delegate(.selected(beach)))

            case .backTapped:
                switch state.screen {
                case .map:
                    state.screen = .search
                    return .cancel(id: CancelID.currentLocation)

                case .search:
                    return .run { _ in await dismiss() }
                }

            case .binding, .delegate:
                return .none
            }
        }
    }
}

// MARK: - Types

extension LocationPickerFeature {

    enum Screen: Equatable {
        case search
        case map
    }

    enum SearchStatus: Equatable {
        case idle
        case results([PlaceSearchResult])
        case empty
    }

    enum BeachLookup: Equatable {
        case idle
        case found(Beach)
        case notFound
    }

    struct CameraTarget: Equatable {
        var center: Coordinate
        var revision: Int = 0
    }
}

// MARK: - Functions

extension LocationPickerFeature {

    static let nearbyBeachRadius: CLLocationDistance = 3_000

    private nonisolated enum CancelID {
        case currentLocation
    }

    private func fetchCurrentLocation(_ state: inout State) -> Effect<Action> {
        state.isLocating = true

        return .run { send in
            await send(.currentLocationResponse(Result {
                try await locationClient.currentLocation()
            }))
        }
        .cancellable(id: CancelID.currentLocation, cancelInFlight: true)
    }

    private func moveCamera(to center: Coordinate, state: inout State) {
        state.mapCenter = center
        state.cameraTarget = CameraTarget(center: center, revision: state.cameraTarget.revision + 1)
        lookUpBeach(at: center, state: &state)
    }

    /// 핀 근처 해변을 찾아요. 다른 해변으로 바뀌면 선택을 풀어요.
    private func lookUpBeach(at center: Coordinate, state: inout State) {
        let previousBeach = state.foundBeach

        if let beach = Self.nearestBeach(to: center, in: state.allBeaches) {
            state.beachLookup = .found(beach)
        } else {
            state.beachLookup = .notFound
        }

        if state.foundBeach != previousBeach {
            state.isBeachSelected = false
        }
    }

    static func nearestBeach(to center: Coordinate, in beaches: [Beach]) -> Beach? {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return beaches
            .map { beach in
                (beach, CLLocation(latitude: beach.latitude, longitude: beach.longitude).distance(from: centerLocation))
            }
            .filter { $0.1 <= nearbyBeachRadius }
            .min { $0.1 < $1.1 }?
            .0
    }
}
