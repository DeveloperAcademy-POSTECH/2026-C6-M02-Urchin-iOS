//
//  GoalRecordsFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct GoalRecordsFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Presents var recordDetail: RecordDetailFeature.State?

        let goal: HomeGoal
        var records: [HomeGoalRecord]
        let now: Date
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case recordTapped(HomeGoalRecord.ID)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case closed
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .send(.delegate(.closed))

            // TODO: 실제 기록 데이터가 연결되면 해당 기록 상세로 이동해요. 지금은 Mock ID라 불러오지 못해요.
            case let .recordTapped(recordID):
                state.recordDetail = RecordDetailFeature.State(recordID: recordID)
                return .none

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return .none

            case let .recordDetail(.presented(.delegate(.deleted(recordID)))),
                 let .recordDetail(.presented(.delegate(.reported(recordID)))):
                state.recordDetail = nil
                state.records.removeAll { $0.id == recordID }
                return .none

            case .recordDetail(.presented(.delegate(.blocked))):
                state.recordDetail = nil
                return .none

            case .recordDetail, .delegate:
                return .none
            }
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
    }
}
