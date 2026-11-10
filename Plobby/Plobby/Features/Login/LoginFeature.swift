//
//  LoginFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import Foundation

import ComposableArchitecture

/// 온보딩을 본 뒤 로그인하지 않은 상태로 앱을 켜거나, 로그아웃했을 때 보여주는 화면이에요.
@Reducer
struct LoginFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var signIn = SignInFeature.State()
    }

    // MARK: - Action

    enum Action {
        case browseButtonTapped
        case signIn(SignInFeature.Action)
        case delegate(Delegate)

        enum Delegate {
            case browseWithoutSignUp
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.signIn, action: \.signIn) {
            SignInFeature()
        }

        Reduce { state, action in
            switch action {
            case .browseButtonTapped:
                guard !state.signIn.isSigningIn else { return .none }

                return .send(.delegate(.browseWithoutSignUp))

            case .signIn, .delegate:
                return .none
            }
        }
    }
}
