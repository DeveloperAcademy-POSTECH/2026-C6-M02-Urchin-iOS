//
//  FavoriteBeachSetupFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct FavoriteBeachSetupFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var picker = BeachPickerFeature.State()
    }

    // MARK: - Action

    enum Action {
        case picker(BeachPickerFeature.Action)
        case signUpButtonTapped
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.picker, action: \.picker) {
            BeachPickerFeature()
        }

        Reduce { _, action in
            switch action {
            case .picker, .signUpButtonTapped:
                return .none
            }
        }
    }
}
