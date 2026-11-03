//
//  DatePickerSheetFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct DatePickerSheetFeature {

    @ObservableState
    struct State: Equatable {
        let field: PeriodField
        var date: Date
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case confirmTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case confirmed(PeriodField, Date)
        }
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .confirmTapped:
                return .send(.delegate(.confirmed(state.field, state.date)))
                
            case .binding, .delegate:
                return .none
            }
        }
    }
}
