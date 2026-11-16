//
//  RecordRewardFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RecordRewardFeature {

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        @Shared(.myProfile) var profile
        let recordID: UUID
        var beachName: String?
        var trash = TrashSelection()
        var weightKg: Double?
        var goal: Goal?
        var nickname: String? {
            profile?.nickname
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
        case goalResponse(Result<Goal?, any Error>)
        case nextButtonTapped
        case closeButtonTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case finished(UUID)
            case closed
        }
    }
    
    // MARK: - Dependency

    @Dependency(\.userClient) var userClient
    @Dependency(\.goalClient) var goalClient
    @Dependency(\.date.now) var now

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    state.profile == nil ? fetchMyProfile() : .none,
                    state.goal == nil ? fetchCurrentGoal() : .none
                )
                
            case let .profileResponse(.success(profile)):
                state.$profile.withLock { $0 = profile }
                return .none
                
            case let .profileResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case let .goalResponse(.success(goal)):
                state.goal = goal
                return .none

            case let .goalResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none
                
            case .nextButtonTapped:
                return .send(.delegate(.finished(state.recordID)))
                
            case .closeButtonTapped:
                return .send(.delegate(.closed))
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension RecordRewardFeature {

    private func fetchMyProfile() -> Effect<Action> {
        .run { send in
            await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
        }
    }

    private func fetchCurrentGoal() -> Effect<Action> {
        let now = now
        return .run { send in
            await send(.goalResponse(Result { try await goalClient.fetchCurrentGoal(now) }))
        }
    }
}
