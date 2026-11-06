//
//  BlockedUsersFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/7/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct BlockedUsersFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var blockedUsers: LoadState<IdentifiedArrayOf<BlockedUser>> = .loading
        /// 이 화면에서 차단을 해제한 사용자. 목록에 남겨 두고 "차단하기"로 다시 차단할 수 있어요.
        var unblockedUserIDs: Set<BlockedUser.ID> = []
        /// 차단/해제를 요청 중인 사용자. 응답이 올 때까지 같은 버튼을 다시 누르지 못하게 해요.
        var updatingUserID: BlockedUser.ID?
        var toast = ToastFeature.State()
        
        func isBlocked(_ userID: BlockedUser.ID) -> Bool {
            !unblockedUserIDs.contains(userID)
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case task
        case blockedUsersResponse(Result<[BlockedUser], any Error>)
        case backButtonTapped
        case blockToggleTapped(BlockedUser.ID)
        case blockToggleResponse(Result<Void, any Error>, userID: BlockedUser.ID, isBlocked: Bool)
        case toast(ToastFeature.Action)
    }
    
    // MARK: - Dependency
    
    @Dependency(\.userClient) var userClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.toast, action: \.toast) {
            ToastFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    do {
                        let blockedUsers = try await userClient.fetchBlockedUsers()
                        await send(.blockedUsersResponse(.success(blockedUsers)))
                    } catch {
                        await send(.blockedUsersResponse(.failure(error)))
                    }
                }
                
            case let .blockedUsersResponse(result):
                switch result {
                case let .success(blockedUsers):
                    if blockedUsers.isEmpty {
                        state.blockedUsers = .empty
                        return .none
                    }
                    state.blockedUsers = .loaded(.init(uniqueElements: blockedUsers))
                    state.unblockedUserIDs = []
                case let .failure(error):
                    PlobbyLogger.error(error)
                    state.blockedUsers = .failed
                }
                return .none
                
            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }
                
            case let .blockToggleTapped(userID):
                guard state.updatingUserID == nil else { return .none }
                
                let willBlock = !state.isBlocked(userID)
                state.updatingUserID = userID
                
                return .run { send in
                    do {
                        if willBlock {
                            try await userClient.submitBlock(userID)
                        } else {
                            try await userClient.removeBlock(userID)
                        }
                        await send(.blockToggleResponse(.success(()), userID: userID, isBlocked: willBlock))
                    } catch {
                        await send(.blockToggleResponse(.failure(error), userID: userID, isBlocked: willBlock))
                    }
                }
                
            case let .blockToggleResponse(result, userID, isBlocked):
                state.updatingUserID = nil
                
                guard case let .loaded(blockedUsers) = state.blockedUsers,
                      let nickname = blockedUsers[id: userID]?.nickname
                else { return .none }
                
                switch result {
                case .success:
                    if isBlocked {
                        state.unblockedUserIDs.remove(userID)
                        return .send(.toast(.show("\(nickname)님을 차단했어요")))
                    } else {
                        state.unblockedUserIDs.insert(userID)
                        return .send(.toast(.show("\(nickname)님 차단을 해제했어요")))
                    }
                    
                case let .failure(error):
                    PlobbyLogger.error(error)
                    return .send(.toast(.show(isBlocked ? "차단하지 못했어요" : "차단을 해제하지 못했어요")))
                }
                
            case .toast:
                return .none
            }
        }
    }
}
