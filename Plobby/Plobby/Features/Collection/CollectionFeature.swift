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
        var card = CollectionCardFeature.State()
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
        case shareTapped
        case card(CollectionCardFeature.Action)
        case my(PresentationAction<MyFeature.Action>)
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.card, action: \.card) {
            CollectionCardFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard case .member = state.membershipStatus else { return .none }

                return .run { send in
                    await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
                }

            case let .profileResponse(.success(profile)):
                state.profile = profile
                state.card.nickname = profile?.nickname
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
                return .send(.card(.categorySelected(category)))

            // TODO: 카드 공유 연결
            case .shareTapped:
                return .none

            case .card, .my:
                return .none
            }
        }
        .ifLet(\.$my, action: \.my) {
            MyFeature()
        }
    }
}

// MARK: - Constants

extension CollectionFeature {

    /// 시범 운영에서는 이 종류만 카드로 볼 수 있어요
    static let selectableCategories: Set<TrashCategory> = [.plastic, .glass, .wood]
}
