//
//  SearchBeachFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct SearchBeachFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var query = ""
        var status: SearchStatus = .idle
        @Shared(.beaches) var allBeaches
        @Shared(.favoriteBeaches) var favoriteBeaches
        @Shared(.recentSearches) var recentSearches
        @Shared(.membershipStatus) var membershipStatus
        @Presents var alert: AlertState<Action.Alert>?

        var isMember: Bool {
            if case .member = membershipStatus { true } else { false }
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case searchResponse(Result<[PlaceSearchResult], any Error>)
        case resultTapped(PlaceSearchResult.ID)
        case favoriteTapped(Beach)
        case favoriteResponse(Result<Void, any Error>, beach: Beach, isFavorite: Bool)
        case recentTapped(Beach)
        case recentDeleteTapped(Beach)
        case recentClearTapped
        case backTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {}

        enum Delegate: Equatable {
            case beachSelected(Beach)
        }
    }

    enum SearchStatus: Equatable {
        case idle
        case searching
        case results([PlaceSearchResult])
        case empty
    }

    static let recentSearchLimit = 10

    private nonisolated enum CancelID {
        case search
    }

    // MARK: - Dependency

    @Dependency(\.beachClient) var beachClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.query):
                guard !InputText.isBlank(state.query) else {
                    state.status = .idle
                    return .cancel(id: CancelID.search)
                }

                // 동기화된 해변 목록에서 찾아요. 입력이 멈춘 뒤에만 검색해요.
                state.status = .searching
                return .run { [query = state.query, beaches = state.allBeaches] send in
                    try await clock.sleep(for: .milliseconds(250))
                    await send(.searchResponse(.success(beaches.matching(query).map(PlaceSearchResult.init(beach:)))))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .binding:
                return .none

            case let .searchResponse(.success(results)):
                state.status = results.isEmpty ? .empty : .results(results)
                return .none

            case .searchResponse(.failure):
                state.status = .empty
                return .none

            case let .resultTapped(id):
                guard let beach = state.allBeaches.first(where: { $0.id == id }) else { return .none }
                return select(beach, state: &state)

            case let .favoriteTapped(beach):
                switch FavoriteBeachToggle.toggle(beach, in: state.$favoriteBeaches) {
                case .limitReached:
                    state.alert = .make(.favoriteBeachLimit)
                    return .none

                case let .toggled(isFavorite):
                    return .run { send in
                        await send(.favoriteResponse(
                            Result { try await FavoriteBeachToggle.request(beach, isFavorite: isFavorite, beachClient: beachClient) },
                            beach: beach,
                            isFavorite: isFavorite
                        ))
                    }
                }

            case .favoriteResponse(.success, _, _):
                return .none

            case let .favoriteResponse(.failure(error), beach, isFavorite):
                PlobbyLogger.error(error)
                FavoriteBeachToggle.revert(beach, isFavorite: isFavorite, in: state.$favoriteBeaches)
                return .none

            case let .recentTapped(beach):
                return select(beach, state: &state)

            case let .recentDeleteTapped(beach):
                state.$recentSearches.withLock {
                    $0.removeAll { $0.id == beach.id }
                }
                return .none

            case .recentClearTapped:
                state.$recentSearches.withLock { $0.removeAll() }
                return .none

            case .backTapped:
                return .run { _ in await dismiss() }

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension SearchBeachFeature {

    /// 고른 해변을 최근 검색 맨 앞에 두고 지도에 알려요.
    private func select(_ beach: Beach, state: inout State) -> Effect<Action> {
        state.$recentSearches.withLock {
            $0.removeAll { $0.id == beach.id }
            $0.insert(beach, at: 0)
            $0 = Array($0.prefix(Self.recentSearchLimit))
        }
        return .send(.delegate(.beachSelected(beach)))
    }
}
