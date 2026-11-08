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
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
        case profileTapped
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

            case .card, .my:
                return .none
            }
        }
        .ifLet(\.$my, action: \.my) {
            MyFeature()
        }
    }
}
