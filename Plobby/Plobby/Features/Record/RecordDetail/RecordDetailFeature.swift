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
    }
    
    // MARK: - Action
    
    enum Action {
        case closeButtonTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case closed
        }
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .send(.delegate(.closed))
            case .delegate:
                return .none
            }
        }
    }
}
