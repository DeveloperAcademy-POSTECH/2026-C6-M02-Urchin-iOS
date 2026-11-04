//
//  TrashPickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct TrashPickerFeature {

    @ObservableState
    struct State: Equatable {
        var selection: TrashSelection
    }

    enum Action {
        case confirmTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case confirmed(TrashSelection)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .confirmTapped:
                return .send(.delegate(.confirmed(state.selection)))
                
            case .delegate:
                return .none
            }
        }
    }
}
