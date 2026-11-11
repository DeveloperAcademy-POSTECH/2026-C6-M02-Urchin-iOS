//
//  MapFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import UIKit

import ComposableArchitecture

@Reducer
struct MapFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
        @Presents var beachSheet: BeachSheetFeature.State?
        var selectedBeachID: UUID? {
            beachSheet?.beach.id
        }

        var authorization: LocationAuthorization = .notDetermined
        var cameraCommand: CameraCommand = .region(center: .fallback, meters: MapFeature.defaultSpanMeters)
        var cameraRevision = 0
        var recordCounts: [UUID: Int] = [:]
        var isLocating = false
        var hasRequestedLocation = false
        var currentLocation: Coordinate?
        var isShowingCurrentLocation = false
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
        case locationResponse(Result<Coordinate, any Error>, isButtonRequest: Bool)
        case sceneBecameActive
        case currentLocationButtonTapped
        case locationSettingsTapped
        case markerTapped(BeachMarker)
        case clusterTapped([BeachMarker])
        case favoriteChipTapped(Beach)
        case cameraMovedAwayFromCurrentLocation
        case searchButtonTapped
        case beachSheet(PresentationAction<BeachSheetFeature.Action>)
        case path(StackActionOf<Path>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case recordStartRequested(Beach, RecordType)
            case loginRequired
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
    private static let metersPerDegree: Double = 111_000
    private static let clusterZoomPadding: Double = 1.6
    private static let sheetDismissDelay: Duration = .milliseconds(350)

    private nonisolated enum CancelID {
        case location
    }

    // MARK: - Dependency

    @Dependency(\.beachClient) var beachClient
    @Dependency(\.locationClient) var locationClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.continuousClock) var clock

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                var effects: [Effect<Action>] = [fetchRecordCounts()]

                if state.isMember {
                    effects.append(fetchFavoriteBeaches())
                }

                if !state.hasRequestedLocation {
                    state.hasRequestedLocation = true
                    effects.append(fetchCurrentLocation(&state, isButtonRequest: false))
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

            case let .locationResponse(.success(coordinate), isButtonRequest):
                state.isLocating = false
                state.authorization = .authorized
                state.currentLocation = coordinate
                moveCamera(to: coordinate, meters: Self.defaultSpanMeters, state: &state)
                state.isShowingCurrentLocation = isButtonRequest
                return .none

            case let .locationResponse(.failure(error), isButtonRequest):
                state.isLocating = false

                guard error as? LocationClientError == .denied else {
                    PlobbyLogger.error(error)
                    return .none
                }

                state.authorization = .denied
                return isButtonRequest ? .send(.locationSettingsTapped) : .none

            case .sceneBecameActive:
                switch locationClient.authorization() {
                case .denied:
                    state.authorization = .denied
                    return .none

                case .authorized where state.authorization == .denied:
                    return fetchCurrentLocation(&state, isButtonRequest: false)

                case .authorized, .notDetermined:
                    return .none
                }

            case .currentLocationButtonTapped:
                return fetchCurrentLocation(&state, isButtonRequest: true)

            case .locationSettingsTapped:
                return .run { _ in
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    await openURL(url)
                }

            case let .markerTapped(marker):
                moveCamera(to: marker.beach.coordinate, meters: Self.beachSpanMeters, state: &state)
                state.beachSheet = BeachSheetFeature.State(beach: marker.beach)
                return .none

            case let .clusterTapped(markers):
                guard !markers.isEmpty else { return .none }

                let latitudes = markers.map(\.beach.latitude)
                let longitudes = markers.map(\.beach.longitude)
                let center = Coordinate(
                    latitude: (latitudes.min()! + latitudes.max()!) / 2,
                    longitude: (longitudes.min()! + longitudes.max()!) / 2
                )
                let spanDegrees = max(latitudes.max()! - latitudes.min()!, longitudes.max()! - longitudes.min()!)
                let meters = max(spanDegrees * Self.metersPerDegree * Self.clusterZoomPadding, Self.beachSpanMeters)
                moveCamera(to: center, meters: meters, state: &state)
                return .none

            case let .favoriteChipTapped(beach):
                moveCamera(to: beach.coordinate, meters: Self.beachSpanMeters, state: &state)
                state.beachSheet = BeachSheetFeature.State(beach: beach)
                return .none

            case .cameraMovedAwayFromCurrentLocation:
                state.isShowingCurrentLocation = false
                return .none

            case .searchButtonTapped:
                state.beachSheet = nil
                state.path.append(.searchBeach(SearchBeachFeature.State()))
                return .none

            case .beachSheet(.presented(.delegate(.homeTapped))) where !state.isMember,
                 .beachSheet(.presented(.delegate(.loginRequired))):
                state.beachSheet = nil
                return .run { send in
                    try await clock.sleep(for: Self.sheetDismissDelay)
                    await send(.delegate(.loginRequired))
                }

            case let .beachSheet(.presented(.delegate(.homeTapped(beach)))):
                state.beachSheet = nil
                state.path.append(.beachHome(BeachHomeFeature.State(beach: beach)))
                return .none

            case .beachSheet(.presented(.delegate(.closed))):
                state.beachSheet = nil
                return .none

            case let .beachSheet(.presented(.delegate(.recordStartTapped(beach, type)))):
                state.beachSheet = nil
                return .send(.delegate(.recordStartRequested(beach, type)))

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
        state.isShowingCurrentLocation = false
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

    private func fetchCurrentLocation(_ state: inout State, isButtonRequest: Bool) -> Effect<Action> {
        state.isLocating = true
        return .run { send in
            await send(.locationResponse(
                Result { try await locationClient.currentLocation() },
                isButtonRequest: isButtonRequest
            ))
        }
        .cancellable(id: CancelID.location, cancelInFlight: true)
    }
}

// MARK: - CameraCommand

enum CameraCommand: Equatable {
    case region(center: Coordinate, meters: Double)
}

extension MapFeature.Path.State: Equatable {}
