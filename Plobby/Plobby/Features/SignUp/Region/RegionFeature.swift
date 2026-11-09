//
//  RegionFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation

import ComposableArchitecture

/// 회원가입의 관심 해변 단계예요. 해변 고르기는 `BeachPickerFeature`가 맡고, 여기서는 다음 단계로 넘기기만 해요.
@Reducer
struct RegionFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var picker = BeachPickerFeature.State()
    }

    // MARK: - Action

    enum Action {
        case picker(BeachPickerFeature.Action)
        case nextButtonTapped
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.picker, action: \.picker) {
            BeachPickerFeature()
        }

        Reduce { _, action in
            switch action {
            case .picker, .nextButtonTapped:
                return .none
            }
        }
    }
}
