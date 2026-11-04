//
//  MyFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct MyFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
        var profile: Profile?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard case .member = state.membershipStatus else { return .none }

                return fetchMyProfile()

            case let .profileResponse(.success(profile)):
                state.profile = profile
                return .none

            case let .profileResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none
            }
        }
    }
}

// MARK: - Functions

extension MyFeature {

    private func fetchMyProfile() -> Effect<Action> {
        .run { send in
            await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
        }
    }
}
