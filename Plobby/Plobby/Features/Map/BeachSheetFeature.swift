//
//  BeachSheetFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct BeachSheetFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var beach: Beach
        var content: Content = .loading
        @Shared(.favoriteBeaches) var favoriteBeaches
        @Shared(.membershipStatus) var membershipStatus
        @Presents var alert: AlertState<Action.Alert>?
        var isActivityPickerPresented = false

        var isFavorite: Bool {
            favoriteBeaches.contains { $0.id == beach.id }
        }

        var isMember: Bool {
            if case .member = membershipStatus { true } else { false }
        }

        init(beach: Beach) {
            self.beach = beach
        }
    }

    // MARK: - Action

    enum Action {
        case task
        case summaryResponse(Result<BeachSummary, any Error>)
        case favoriteTapped
        case favoriteResponse(Result<Void, any Error>, beach: Beach, isFavorite: Bool)
        case closeTapped
        case homeTapped
        case recordStartTapped
        case activityPicked(RecordType)
        case activityPickerDismissed
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {}

        enum Delegate: Equatable {
            case closed
            case homeTapped(Beach)
            case recordStartTapped(Beach, RecordType)
            case loginRequired
            case favoriteChanged(isFavorite: Bool)
        }
    }

    enum Content: Equatable {
        case loading
        case received(BeachSummary)
        case empty
        case failed
    }

    static let photoLimit = 10

    // MARK: - Dependency

    @Dependency(\.beachClient) var beachClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.content = .loading
                return .run { [beachID = state.beach.id] send in
                    await send(.summaryResponse(Result {
                        try await beachClient.fetchBeachRecords(beachID, nil).summary(photoLimit: Self.photoLimit)
                    }))
                }

            case let .summaryResponse(.success(summary)):
                state.content = summary.recordCount == 0 ? .empty : .received(summary)
                return .none

            case let .summaryResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.content = .failed
                return .none

            case .favoriteTapped:
                switch FavoriteBeachToggle.toggle(state.beach, in: state.$favoriteBeaches) {
                case .limitReached:
                    state.alert = .make(.favoriteBeachLimit)
                    return .none

                case let .toggled(isFavorite):
                    return .run { [beach = state.beach] send in
                        await send(.favoriteResponse(
                            Result { try await FavoriteBeachToggle.request(beach, isFavorite: isFavorite, beachClient: beachClient) },
                            beach: beach,
                            isFavorite: isFavorite
                        ))
                    }
                }

            case let .favoriteResponse(.success, _, isFavorite):
                return .send(.delegate(.favoriteChanged(isFavorite: isFavorite)))

            case let .favoriteResponse(.failure(error), beach, isFavorite):
                PlobbyLogger.error(error)
                FavoriteBeachToggle.revert(beach, isFavorite: isFavorite, in: state.$favoriteBeaches)
                return .none

            case .closeTapped:
                return .send(.delegate(.closed))

            case .homeTapped:
                return .send(.delegate(.homeTapped(state.beach)))

            case .recordStartTapped:
                guard state.isMember else { return .send(.delegate(.loginRequired)) }

                state.isActivityPickerPresented = true
                return .none

            case let .activityPicked(type):
                state.isActivityPickerPresented = false
                return .send(.delegate(.recordStartTapped(state.beach, type)))

            case .activityPickerDismissed:
                state.isActivityPickerPresented = false
                return .none

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
