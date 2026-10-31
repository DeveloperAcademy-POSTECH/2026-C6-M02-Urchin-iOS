//
//  CompleteFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import ComposableArchitecture

@Reducer
struct CompleteFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        
    }

    // MARK: - Action
    
    enum Action {
        case completeButtonTapped
    }

    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .completeButtonTapped: .none
            }
        }
    }
}
