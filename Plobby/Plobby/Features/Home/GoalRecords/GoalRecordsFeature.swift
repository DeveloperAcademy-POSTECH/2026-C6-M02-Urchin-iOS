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
        @Presents var recordMenu: RecordMenuFeature.State?

        let goal: Goal
        var records: [RecordSummary] = []
        var recordFilter: RecordFilter = .all
        var isLoading = true
        let now: Date

        var filteredRecords: [RecordSummary] {
            guard let recordType = recordFilter.recordType else { return records }
            return records.filter { $0.recordType == recordType }
        }

        var memberID: UUID? {
            guard case let .member(user) = membershipStatus else { return nil }
            return user.id
        }
    }

    // MARK: - Action

    enum Action {
        case task
        case recordsResponse(Result<[RecordSummary], any Error>)
        case recordFilterChanged(RecordFilter)
        case backButtonTapped
        case recordTapped(RecordSummary.ID)
        case recordMenuSelected(RecordSummary, RecordMenuFeature.Menu)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case recordMenu(PresentationAction<RecordMenuFeature.Action>)
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

            case .recordTapped where state.membershipStatus == .guest:
                return .send(.delegate(.loginRequired))

            case let .recordTapped(recordID):
                state.recordDetail = RecordDetailFeature.State(recordID: recordID)
                return .none

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return .none

            case let .recordDetail(.presented(.delegate(.deleted(recordID)))):
                state.recordDetail = nil
                state.records.removeAll { $0.id == recordID }
                return .none

            case let .recordDetail(.presented(.delegate(.blocked(userID)))):
                state.recordDetail = nil
                state.records.removeAll { $0.userID == userID }
                return .none

            case let .recordMenuSelected(record, menu):
                state.recordMenu = RecordMenuFeature.State(record: record)
                return .send(.recordMenu(.presented(.menuSelected(menu))))

            case .recordMenu(.presented(.delegate(.updated))):
                state.recordMenu = nil
                return .send(.task)

            case let .recordMenu(.presented(.delegate(.deleted(recordID)))),
                 let .recordMenu(.presented(.delegate(.reported(recordID)))):
                state.recordMenu = nil
                state.records.removeAll { $0.id == recordID }
                return .none

            case let .recordMenu(.presented(.delegate(.blocked(userID)))):
                state.recordMenu = nil
                state.records.removeAll { $0.userID == userID }
                return .none

            case let .recordFilterChanged(filter):
                state.recordFilter = filter
                return .none

            case .recordDetail, .recordMenu, .delegate:
                return .none
            }
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$recordMenu, action: \.recordMenu) {
            RecordMenuFeature()
        }
    }
}
