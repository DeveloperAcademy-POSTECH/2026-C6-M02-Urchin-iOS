//
//  RegionFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import ComposableArchitecture

@Reducer
struct RegionFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var selectedSea = 0
    }

    // MARK: - Action
    
    enum Action {
        case nextButtonTapped
    }

    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextButtonTapped: .none
            }
        }
    }
}
