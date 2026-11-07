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
        let recordID: UUID
        var beachName: String?
        var trash = TrashSelection()
        var weightKg: Double?
        var nickname: String?
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case profileResponse(Result<Profile?, any Error>)
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

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.profileResponse(Result { try await userClient.fetchMyProfile() }))
                }
                
            case let .profileResponse(.success(profile)):
                state.nickname = profile?.nickname
                return .none
                
            case let .profileResponse(.failure(error)):
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
