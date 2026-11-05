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
        var trash = TrashSelection()
    }
    
    // MARK: - Action
    
    enum Action {
        case nextButtonTapped
        case closeButtonTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case finished(UUID)
            case closed
        }
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
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
