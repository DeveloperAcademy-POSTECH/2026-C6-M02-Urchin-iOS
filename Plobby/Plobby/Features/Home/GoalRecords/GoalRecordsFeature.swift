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
        @Shared(.membershipStatus) var membershipStatus
        @Presents var recordDetail: RecordDetailFeature.State?

        let goal: Goal
        var records: [RecordSummary] = []
        var isLoading = true
        let now: Date
    }

    // MARK: - Action

    enum Action {
        case task
        case recordsResponse(Result<[RecordSummary], any Error>)
        case backButtonTapped
        case recordTapped(RecordSummary.ID)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
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
                let goal = state.goal
                return .run { send in
                    await send(.recordsResponse(Result { try await goalClient.fetchGoalRecords(goal) }))
                }

            case let .recordsResponse(.success(records)):
                state.isLoading = false
                state.records = records
                return .none

            case let .recordsResponse(.failure(error)):
                state.isLoading = false
                PlobbyLogger.error(error)
                return .none

            case .backButtonTapped:
                return .send(.delegate(.closed))

            // 비회원은 기록 상세에 들어가지 못하고 로그인을 요청해요.
            case .recordTapped where state.membershipStatus == .guest:
                return .send(.delegate(.loginRequired))

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

            case let .recordDetail(.presented(.delegate(.blocked(userID)))):
                state.recordDetail = nil
                state.records.removeAll { $0.userID == userID }
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
