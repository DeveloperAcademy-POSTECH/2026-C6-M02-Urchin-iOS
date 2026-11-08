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
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
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

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard case .member = state.membershipStatus else { return .none }

                return .run { send in
                    await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
                }

            case let .profileResponse(.success(profile)):
                state.profile = profile
                for id in state.cards.ids {
                    state.cards[id: id]?.nickname = profile?.nickname
                }
                return .none

            case let .profileResponse(.failure(error)):
                PlobbyLogger.error(error)
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

    // TODO: 컬렉션 데이터 연동 후 실제 개수로 교체
    static let initialCards = IdentifiedArray(uniqueElements: categoryOrder.map { category in
        CollectionCardFeature.State(category: category, collectedCount: sampleCounts[category, default: 0])
    })

    private static let sampleCounts: [TrashCategory: Int] = [
        .plastic: 128, .glass: 12, .metal: 4, .fishingGear: 19,
        .styrofoam: 8, .can: 17, .rubber: 3, .etc: 3
    ]
}
