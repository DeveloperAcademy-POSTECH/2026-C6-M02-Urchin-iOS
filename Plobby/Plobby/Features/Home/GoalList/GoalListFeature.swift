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

        let currentGoal: HomeGoal
        let pastGoals: [HomeGoal]
        let now: Date
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case currentGoalRecordsTapped
        case pastGoalTapped(HomeGoal.ID)
        case goalRecords(PresentationAction<GoalRecordsFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case closed
        }
    }

    // MARK: - Dependency

    @Dependency(\.calendar) var calendar

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.closed))

            case .currentGoalRecordsTapped:
                state.goalRecords = recordsState(for: state.currentGoal, now: state.now)
                return .none

            case let .pastGoalTapped(goalID):
                guard let goal = state.pastGoals.first(where: { $0.id == goalID }) else { return .none }

                state.goalRecords = recordsState(for: goal, now: state.now)
                return .none

            case .goalRecords(.presented(.delegate(.closed))):
                state.goalRecords = nil
                return .none

            case .goalRecords, .delegate:
                return .none
            }
        }
        .ifLet(\.$goalRecords, action: \.goalRecords) {
            GoalRecordsFeature()
        }
    }

    private func recordsState(for goal: HomeGoal, now: Date) -> GoalRecordsFeature.State {
        GoalRecordsFeature.State(
            goal: goal,
            records: HomeMock.records(for: goal, calendar: calendar),
            now: now
        )
    }
}
