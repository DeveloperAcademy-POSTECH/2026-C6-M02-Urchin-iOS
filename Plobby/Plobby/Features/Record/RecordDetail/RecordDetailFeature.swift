//
//  RecordDetailFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RecordDetailFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let recordID: UUID
        var loadState: LoadState = .loading
        var currentPhotoIndex = 0
        var isLikeUpdating = false
        @Presents var editForm: RecordFormFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        
        init(recordID: UUID) {
            self.recordID = recordID
        }
        
        var record: RecordDetail? {
            guard case let .loaded(record) = loadState else { return nil }
            return record
        }
        
        var trashSummary: TrashSummary? {
            record.map(TrashSummary.init)
        }
    }
    
    // MARK: - LoadState
    
    enum LoadState: Equatable {
        case loading
        case loaded(RecordDetail)
        case failed
    }
    
    // MARK: - TrashSummary
    
    nonisolated struct TrashSummary: Equatable {
        let totalCount: Int
        let weight: Double?
        let items: [RecordDetail.Trash]

        init(_ record: RecordDetail) {
            totalCount = record.trashCount
            weight = record.weightKg
            items = record.trash.sorted { $0.quantity > $1.quantity }
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case task
        case recordResponse(Result<RecordDetail, any Error>)
        case photoPageChanged(Int)
        case likeTapped
        case likeResponse(Result<Void, any Error>)
        case backTapped
        case moreMenuSelected(MoreMenu)
        case editForm(PresentationAction<RecordFormFeature.Action>)
        case alert(PresentationAction<Alert>)
        case deleteResponse(Result<Void, any Error>)
        case reportResponse(Result<Void, any Error>)
        case blockResponse(Result<Void, any Error>, userID: UUID)
        case delegate(Delegate)
        
        enum MoreMenu: Equatable {
            case editTapped
            case deleteTapped
            case reportTapped
            case blockTapped
        }
        
        enum Alert: Equatable {
            case confirmDeleteTapped
            case confirmBlockTapped
            case deletedConfirmTapped
            case reportedConfirmTapped
            case blockedConfirmTapped(userID: UUID)
        }
        
        @CasePathable
        enum Delegate {
            case closed
            /// 신고를 마쳤어요. 부모는 상세를 닫고 목록에서 이 기록을 빼요.
            case reported(UUID)
            /// 작성자를 차단했어요. 부모는 상세를 닫고 그 사용자의 기록을 모두 빼요.
            case blocked(userID: UUID)
            case deleted(UUID)
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.recordClient) var recordClient
    @Dependency(\.userClient) var userClient
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce {
            state,
            action in
            switch action {
            case .task:
                state.loadState = .loading
                return .run { [recordID = state.recordID] send in
                    await send(.recordResponse(Result { try await recordClient.fetchRecord(recordID) }))
                }
                
            case let .recordResponse(.success(record)):
                state.loadState = .loaded(record)
                state.currentPhotoIndex = 0
                return .none
                
            case let .recordResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.loadState = .failed
                return .none
                
            case let .photoPageChanged(index):
                state.currentPhotoIndex = index
                return .none
                
            case .likeTapped:
                guard !state.isLikeUpdating,
                      case var .loaded(record) = state.loadState
                else { return .none }
                
                let willLike = !record.likedByMe
                record.likedByMe = willLike
                record.likeCount += willLike ? 1 : -1
                state.loadState = .loaded(record)
                state.isLikeUpdating = true
                
                return .run { [recordID = state.recordID] send in
                    await send(.likeResponse(Result {
                        if willLike {
                            try await recordClient.like(recordID)
                        } else {
                            try await recordClient.unlike(recordID)
                        }
                    }))
                }
                
            case .likeResponse(.success):
                state.isLikeUpdating = false
                return .none
                
            case let .likeResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isLikeUpdating = false
                
                if case var .loaded(record) = state.loadState {
                    record.likedByMe.toggle()
                    record.likeCount += record.likedByMe ? 1 : -1
                    state.loadState = .loaded(record)
                }
                return .none
                
            case .backTapped:
                return .send(.delegate(.closed))
                
            case .moreMenuSelected(.editTapped):
                guard let record = state.record else { return .none }
                
                state.editForm = RecordFormFeature.State(editing: record)
                return .none
                
            case .moreMenuSelected(.deleteTapped):
                state.alert = .make(.recordDeleteConfirm, confirm: .confirmDeleteTapped)
                return .none
                
            case .moreMenuSelected(.reportTapped):
                return .run { [recordID = state.recordID] send in
                    await send(.reportResponse(Result { try await recordClient.reportRecord(recordID) }))
                }
                
            case .reportResponse(.success):
                state.alert = .make(.recordReported, confirm: .reportedConfirmTapped)
                return .none
                
            case let .reportResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.recordReportFailed)
                return .none
                
            case .alert(.presented(.reportedConfirmTapped)):
                return .send(.delegate(.reported(state.recordID)))
                
            case .moreMenuSelected(.blockTapped):
                state.alert = .make(.userBlockConfirm, confirm: .confirmBlockTapped)
                return .none
                
            case .editForm(.presented(.delegate(.recordUpdated))):
                state.editForm = nil
                return .send(.task)
                
            case .editForm(.presented(.delegate(.closed))):
                state.editForm = nil
                return .none
                
            case .alert(.presented(.confirmDeleteTapped)):
                return .run { [recordID = state.recordID] send in
                    await send(.deleteResponse(Result {
                        try await recordClient.removeRecord(recordID)
                    }))
                }
                
            case .alert(.presented(.confirmBlockTapped)):
                guard let record = state.record else { return .none }

                return .run { [userID = record.userID] send in
                    await send(.blockResponse(Result { try await userClient.submitBlock(userID) }, userID: userID))
                }

            case let .blockResponse(.success, userID):
                state.alert = .make(.userBlocked, confirm: .blockedConfirmTapped(userID: userID))
                return .none

            case let .blockResponse(.failure(error), _):
                PlobbyLogger.error(error)
                state.alert = .make(.userBlockFailed)
                return .none

            case let .alert(.presented(.blockedConfirmTapped(userID))):
                return .send(.delegate(.blocked(userID: userID)))
                
            case .deleteResponse(.success):
                state.alert = .make(.recordDeleted, confirm: .deletedConfirmTapped)
                return .none
                
            case .alert(.presented(.deletedConfirmTapped)):
                return .send(.delegate(.deleted(state.recordID)))
                
            case let .deleteResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.recordDeleteFailed)
                return .none
                
            case .editForm,
                    .alert,
                    .delegate:
                return .none
            }
        }
        .ifLet(\.$editForm, action: \.editForm) {
            RecordFormFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
