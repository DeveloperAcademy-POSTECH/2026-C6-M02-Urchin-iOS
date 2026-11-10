//
//  CollectionFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import ComposableArchitecture

@Reducer
struct CollectionFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
        @Presents var my: MyFeature.State?
        var profile: Profile?
        var cards: IdentifiedArrayOf<CollectionCardFeature.State> = CollectionFeature.initialCards
        var selectedCategory: TrashCategory = CollectionFeature.categoryOrder[0]
        var isCategorySheetPresented = false
        var isTrashCountsLoaded = false
        var shareRequestCount = 0
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
        case trashCountsResponse(Result<[TrashCategory: Int], any Error>)
        case profileTapped
        case allCategoryTapped
        case categorySheetPresentationChanged(Bool)
        case categoryTapped(TrashCategory)
        case cardScrolled(TrashCategory)
        case cards(IdentifiedActionOf<CollectionCardFeature>)
        case shareButtonTapped
        case my(PresentationAction<MyFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case loginRequired
            case recordStartRequested
        }
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient
    @Dependency(\.recordClient) var recordClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            if case .guest = state.membershipStatus, action.isUserInteraction {
                return .send(.delegate(.loginRequired))
            }

            switch action {
            case .onAppear:
                guard case let .member(user) = state.membershipStatus else {
                    state.isTrashCountsLoaded = true
                    return .none
                }

                return .merge(
                    .run { send in
                        await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
                    }
                    .cancellable(id: CancelID.profile, cancelInFlight: true),
                    .run { send in
                        await send(.trashCountsResponse(Result { try await recordClient.fetchTrashCounts(user.id) }))
                    }
                    .cancellable(id: CancelID.trashCounts, cancelInFlight: true)
                )

            case let .profileResponse(.success(profile)):
                state.profile = profile
                for id in state.cards.ids {
                    state.cards[id: id]?.nickname = profile?.nickname
                }
                return .none

            case let .profileResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case let .trashCountsResponse(.success(counts)):
                for category in state.cards.ids {
                    state.cards[id: category]?.collectedCount = counts[category, default: 0]
                }
                state.isTrashCountsLoaded = true
                return .none

            case let .trashCountsResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isTrashCountsLoaded = true
                return .none

            case .profileTapped:
                state.my = MyFeature.State()
                return .none

            case .allCategoryTapped:
                state.isCategorySheetPresented = true
                return .none

            case let .categorySheetPresentationChanged(isPresented):
                state.isCategorySheetPresented = isPresented
                return .none

            case let .categoryTapped(category):
                state.isCategorySheetPresented = false
                state.selectedCategory = category
                return .none

            case let .cardScrolled(category):
                state.selectedCategory = category
                return .none

            case .shareButtonTapped:
                state.shareRequestCount += 1
                return .none

            case .cards(.element(_, .delegate(.recordStartRequested))):
                return .send(.delegate(.recordStartRequested))

            case .cards, .my, .delegate:
                return .none
            }
        }
        .forEach(\.cards, action: \.cards) {
            CollectionCardFeature()
        }
        .ifLet(\.$my, action: \.my) {
            MyFeature()
        }
    }
}

// MARK: - Constants

extension CollectionFeature {

    static let categoryOrder: [TrashCategory] = [
        .glass, .plastic, .metal, .wood, .fishingGear, .clothing,
        .styrofoam, .can, .paper, .rubber, .etc
    ]

    static let initialCards = IdentifiedArray(uniqueElements: categoryOrder.map { category in
        CollectionCardFeature.State(category: category, collectedCount: 0)
    })

    private nonisolated enum CancelID {
        case profile
        case trashCounts
    }
}

// MARK: - Action

extension CollectionFeature.Action {

    var isUserInteraction: Bool {
        switch self {
        case .allCategoryTapped, .shareButtonTapped:
            true
        default:
            false
        }
    }
}
