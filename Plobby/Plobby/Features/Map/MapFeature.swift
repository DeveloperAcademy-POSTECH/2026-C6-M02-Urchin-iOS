//
//  MapFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation
import UIKit

import ComposableArchitecture

@Reducer
struct MapFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        @Presents var beachSheet: BeachSheetFeature.State?
        /// 바텀시트가 열린 해변. 이 핀은 초록 배경으로 그려요.
        var selectedBeachID: UUID? {
            beachSheet?.beach.id
        }

        var authorization: LocationAuthorization = .notDetermined
        var cameraCommand: CameraCommand = .region(center: .fallback, meters: MapFeature.defaultSpanMeters)
        /// 같은 곳으로 다시 옮길 때도 지도가 반응하도록 올려요.
        var cameraRevision = 0
        var recordCounts: [UUID: Int] = [:]
        var isLocating = false
        var hasRequestedLocation = false
        @Shared(.beaches) var allBeaches
        @Shared(.favoriteBeaches) var favoriteBeaches
        @Shared(.membershipStatus) var membershipStatus

        var markers: [BeachMarker] {
            allBeaches.map { BeachMarker(beach: $0, recordCount: recordCounts[$0.id] ?? 0) }
        }

        var isLocationAuthorized: Bool {
            authorization == .authorized
        }

        var isMember: Bool {
            if case .member = membershipStatus { true } else { false }
        }
    }

    // MARK: - Action

    enum Action {
        case task
        case recordCountsResponse(Result<[UUID: Int], any Error>)
        case favoriteBeachesResponse([Beach])
        case locationResponse(Result<Coordinate, any Error>, opensSettingsIfDenied: Bool)
        case sceneBecameActive
        case currentLocationButtonTapped
        case locationSettingsTapped
        case markerTapped(BeachMarker)
        case searchButtonTapped
        case beachSheet(PresentationAction<BeachSheetFeature.Action>)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            /// 기록이 없는 해변에서 첫 기록을 시작하려고 해요.
            case recordStartRequested
        }
    }

    @Reducer
    enum Path {
        case beachHome(BeachHomeFeature)
        case searchBeach(SearchBeachFeature)
        case recordDetail(RecordDetailFeature)
    }

    static let defaultSpanMeters: Double = 5_000
    static let beachSpanMeters: Double = 2_000

    private nonisolated enum CancelID {
        case location
    }

    // MARK: - Dependency

    @Dependency(\.beachClient) var beachClient
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.openURL) var openURL

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                var effects: [Effect<Action>] = [fetchRecordCounts()]

                if state.isMember {
                    effects.append(fetchFavoriteBeaches())
                }

                // 지도 탭을 처음 열 때만 위치 권한을 물어봐요.
                if !state.hasRequestedLocation {
                    state.hasRequestedLocation = true
                    effects.append(fetchCurrentLocation(&state, opensSettingsIfDenied: false))
                }
                return .merge(effects)

            case let .recordCountsResponse(.success(counts)):
                state.recordCounts = counts
                return .none

            case let .recordCountsResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case let .favoriteBeachesResponse(beaches):
                state.$favoriteBeaches.withLock { $0 = beaches }
                return .none

            case let .locationResponse(.success(coordinate), _):
                state.isLocating = false
                state.authorization = .authorized
                moveCamera(to: coordinate, meters: Self.defaultSpanMeters, state: &state)
                return .none

            case let .locationResponse(.failure(error), opensSettingsIfDenied):
                state.isLocating = false

                guard error as? LocationClientError == .denied else {
                    PlobbyLogger.error(error)
                    return .none
                }

                state.authorization = .denied
                return opensSettingsIfDenied ? .send(.locationSettingsTapped) : .none

            // 설정에서 돌아오면 실제 권한을 다시 확인해요. 껐으면 안내를 띄우고, 켰으면 현재 위치로 옮겨요.
            case .sceneBecameActive:
                switch locationClient.authorization() {
                case .denied:
                    state.authorization = .denied
                    return .none

                case .authorized where state.authorization == .denied:
                    return fetchCurrentLocation(&state, opensSettingsIfDenied: false)

                case .authorized, .notDetermined:
                    return .none
                }

            // 거부 상태를 기억해 두지 않고 매번 실제 권한으로 시도해요. 그래도 거부면 설정으로 보내요.
            case .currentLocationButtonTapped:
                return fetchCurrentLocation(&state, opensSettingsIfDenied: true)

            case .locationSettingsTapped:
                return .run { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    await openURL(url)
                }

            case let .markerTapped(marker):
                moveCamera(to: marker.beach.coordinate, meters: Self.beachSpanMeters, state: &state)
                state.beachSheet = BeachSheetFeature.State(beach: marker.beach)
                return .none

            case .searchButtonTapped:
                state.path.append(.searchBeach(SearchBeachFeature.State()))
                return .none

            case let .beachSheet(.presented(.delegate(.homeTapped(beach)))):
                state.beachSheet = nil
                state.path.append(.beachHome(BeachHomeFeature.State(beach: beach)))
                return .none

            case .beachSheet(.presented(.delegate(.closed))):
                state.beachSheet = nil
                return .none

            case .beachSheet(.presented(.delegate(.recordStartTapped))):
                state.beachSheet = nil
                return .send(.delegate(.recordStartRequested))

            case let .path(.element(id, .searchBeach(.delegate(.beachSelected(beach))))):
                state.path.pop(from: id)
                moveCamera(to: beach.coordinate, meters: Self.beachSpanMeters, state: &state)
                state.beachSheet = BeachSheetFeature.State(beach: beach)
                return .none

            case let .path(.element(_, .beachHome(.delegate(.recordSelected(record))))):
                state.path.append(.recordDetail(RecordDetailFeature.State(recordID: record.id)))
                return .none

            case let .path(.element(id, .recordDetail(.delegate(.closed)))),
                let .path(.element(id, .recordDetail(.delegate(.deleted)))):
                state.path.pop(from: id)
                return .none

            // 신고한 기록과 차단한 사용자의 기록은 나에게만 안 보여요. 상세를 닫고, 아래에 쌓인 해변 홈과 지도 배지에서도 빼요.
            case let .path(.element(id, .recordDetail(.delegate(.reported(recordID))))):
                state.path.pop(from: id)
                return hideInBeachHomes(.recordHidden(recordID), state: state)

            case let .path(.element(id, .recordDetail(.delegate(.blocked(userID))))):
                state.path.pop(from: id)
                return hideInBeachHomes(.userBlocked(userID), state: state)

            case .beachSheet, .path, .delegate:
                return .none
            }
        }
        .ifLet(\.$beachSheet, action: \.beachSheet) {
            BeachSheetFeature()
        }
        .forEach(\.path, action: \.path)
    }
}

// MARK: - Functions

extension MapFeature {

    private func moveCamera(to center: Coordinate, meters: Double, state: inout State) {
        state.cameraCommand = .region(center: center, meters: meters)
        state.cameraRevision += 1
    }

    private func hideInBeachHomes(_ action: BeachHomeFeature.Action, state: State) -> Effect<Action> {
        let beachHomeIDs = state.path.ids.filter { state.path[id: $0]?.is(\.beachHome) == true }

        return .merge(
            beachHomeIDs.map { .send(.path(.element(id: $0, action: .beachHome(action)))) }
                + [fetchRecordCounts()]
        )
    }

    private func fetchRecordCounts() -> Effect<Action> {
        .run { send in
            await send(.recordCountsResponse(Result { try await beachClient.fetchRecordCounts() }))
        }
    }

    private func fetchFavoriteBeaches() -> Effect<Action> {
        .run { send in
            await send(.favoriteBeachesResponse(try await beachClient.fetchFavoriteBeaches()))
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }

    /// 권한이 정해지지 않았다면 현재 위치를 받는 순간 권한 팝업이 떠요.
    private func fetchCurrentLocation(_ state: inout State, opensSettingsIfDenied: Bool) -> Effect<Action> {
        state.isLocating = true
        return .run { send in
            await send(.locationResponse(
                Result { try await locationClient.currentLocation() },
                opensSettingsIfDenied: opensSettingsIfDenied
            ))
        }
        .cancellable(id: CancelID.location, cancelInFlight: true)
    }
}

// MARK: - CameraCommand

/// 지도를 어디로 옮길지. MapCameraPosition은 MapKit 뷰 타입이라 State에는 이 값만 둬요.
enum CameraCommand: Equatable {
    case region(center: Coordinate, meters: Double)
}

extension MapFeature.Path.State: Equatable {}
