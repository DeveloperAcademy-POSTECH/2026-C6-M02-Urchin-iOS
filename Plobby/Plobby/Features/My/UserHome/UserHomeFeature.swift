//
//  UserHomeFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct UserHomeFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let userID: UUID
        let nickname: String
        let profileImageURL: URL?
        var records: [RecordSummary] = []
        var recordFilter: RecordFilter = .all
        @Presents var recordDetail: RecordDetailFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var filteredRecords: [RecordSummary] {
            guard let recordType = recordFilter.recordType else { return records }

            return records.filter { $0.recordType == recordType }
        }
    }

    // MARK: - Action

    enum Action {
        case task
        case recordsResponse(Result<[RecordSummary], any Error>)
        case backTapped
        case recordFilterChanged(RecordFilter)
        case recordTapped(RecordSummary.ID)
        case blockMenuTapped
        case blockResponse(Result<Void, any Error>)
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmBlockTapped
            case blockedConfirmTapped
        }

        enum Delegate {
            case closed
            case blocked(userID: UUID)
        }
    }

    // MARK: - Dependency

    @Dependency(\.recordClient) var recordClient
    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                return fetchRecords(userID: state.userID)

            case let .recordsResponse(.success(records)):
                state.records = records
                return .none

            case let .recordsResponse(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case .backTapped:
                return .send(.delegate(.closed))

            case let .recordFilterChanged(filter):
                state.recordFilter = filter
                return .none

            case let .recordTapped(recordID):
                var recordDetail = RecordDetailFeature.State(recordID: recordID)
                recordDetail.opensAuthorHome = false
                state.recordDetail = recordDetail
                return .none

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return fetchRecords(userID: state.userID)

            case let .recordDetail(.presented(.delegate(.reported(recordID)))),
                 let .recordDetail(.presented(.delegate(.deleted(recordID)))):
                state.recordDetail = nil
                state.records.removeAll { $0.id == recordID }
                return .none

            case let .recordDetail(.presented(.delegate(.blocked(userID)))):
                state.recordDetail = nil
                return .send(.delegate(.blocked(userID: userID)))

            case .blockMenuTapped:
                state.alert = .make(.userBlockConfirm, confirm: .confirmBlockTapped)
                return .none

            case .alert(.presented(.confirmBlockTapped)):
                return .run { [userID = state.userID] send in
                    await send(.blockResponse(Result { try await userClient.submitBlock(userID) }))
                }

            case .blockResponse(.success):
                state.alert = .make(.userBlocked, confirm: .blockedConfirmTapped)
                return .none

            case let .blockResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.userBlockFailed)
                return .none

            case .alert(.presented(.blockedConfirmTapped)):
                return .send(.delegate(.blocked(userID: state.userID)))

            case .recordDetail, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension UserHomeFeature {

    private func fetchRecords(userID: UUID) -> Effect<Action> {
        .run { send in
            await send(.recordsResponse(Result { try await recordClient.fetchUserRecords(userID) }))
        }
    }
}
