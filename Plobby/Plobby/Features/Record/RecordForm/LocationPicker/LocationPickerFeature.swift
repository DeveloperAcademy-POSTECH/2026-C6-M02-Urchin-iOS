//
//  LocationPickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct LocationPickerFeature {

    @ObservableState
    struct State: Equatable {
        var selectedBeach: Beach?
    }

    enum Action {
        case beachSelected(Beach)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case selected(Beach)
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .beachSelected(beach):
                state.selectedBeach = beach
                return .send(.delegate(.selected(beach)))
                
            case .delegate:
                return .none
            }
        }
    }
}
