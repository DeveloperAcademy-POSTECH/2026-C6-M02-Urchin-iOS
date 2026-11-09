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
        var selectedCategory: TrashCategory = .plastic
        var isCategorySheetPresented = false
        /// 쓰레기 종류별 개수를 받아왔는지예요. 받기 전에는 쓰레기 쌓기 애니메이션을 시작하지 않아요
        var isTrashCountsLoaded = false
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
        case my(PresentationAction<MyFeature.Action>)
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient
    @Dependency(\.recordClient) var recordClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 비회원은 모은 쓰레기가 없어서 0개로 바로 보여줘요
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

            // 안 주운 종류는 결과에 없어서 0개로 채워요
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
                guard Self.selectableCategories.contains(category) else { return .none }

                state.isCategorySheetPresented = false
                state.selectedCategory = category
                return .none

            case let .cardScrolled(category):
                state.selectedCategory = category
                return .none

            case .cards, .my:
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

    static let selectableCategories: Set<TrashCategory> = [.plastic, .glass, .wood]

    static let categoryOrder: [TrashCategory] = [
        .plastic, .glass, .metal, .wood, .fishingGear, .clothing,
        .styrofoam, .can, .paper, .rubber, .etc
    ]

    /// 서버에서 개수를 받아오기 전에는 0개로 시작해요
    static let initialCards = IdentifiedArray(uniqueElements: categoryOrder.map { category in
        CollectionCardFeature.State(category: category, collectedCount: 0)
    })

    private nonisolated enum CancelID {
        case profile
        case trashCounts
    }
}
