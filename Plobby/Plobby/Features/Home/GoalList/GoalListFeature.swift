//
//  GoalListFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct GoalListFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Presents var goalRecords: GoalRecordsFeature.State?

        var currentGoal: Goal?
        var pastGoals: [Goal] = []
        var isLoading = true
        let now: Date
    }

    // MARK: - Action

    enum Action {
        case task
        case goalsResponse(Result<[Goal], any Error>)
        case backButtonTapped
        case currentGoalRecordsTapped
        case pastGoalTapped(Goal.ID)
        case goalRecords(PresentationAction<GoalRecordsFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case closed
            case loginRequired
        }
    }

    // MARK: - Dependency

    @Dependency(\.goalClient) var goalClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                let now = state.now
                return .run { send in
                    await send(.goalsResponse(Result { try await goalClient.fetchGoals(now) }))
                }

            case let .goalsResponse(.success(goals)):
                state.isLoading = false
                state.currentGoal = goals.first { $0.status(at: state.now) == .inProgress }
                state.pastGoals = goals.filter { $0.id != state.currentGoal?.id }
                return .none

            case let .goalsResponse(.failure(error)):
                state.isLoading = false
                PlobbyLogger.error(error)
                return .none

            case .backButtonTapped:
                return .send(.delegate(.closed))

            case .currentGoalRecordsTapped:
                guard let goal = state.currentGoal else { return .none }

                state.goalRecords = GoalRecordsFeature.State(goal: goal, now: state.now)
                return .none

            case let .pastGoalTapped(goalID):
                guard let goal = state.pastGoals.first(where: { $0.id == goalID }) else { return .none }

                state.goalRecords = GoalRecordsFeature.State(goal: goal, now: state.now)
                return .none

            case .goalRecords(.presented(.delegate(.closed))):
                state.goalRecords = nil
                return .none

            case .goalRecords(.presented(.delegate(.loginRequired))):
                return .send(.delegate(.loginRequired))

            case .goalRecords, .delegate:
                return .none
            }
        }
        .ifLet(\.$goalRecords, action: \.goalRecords) {
            GoalRecordsFeature()
        }
    }
}
