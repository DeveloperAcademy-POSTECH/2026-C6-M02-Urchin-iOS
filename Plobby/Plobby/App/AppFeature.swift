//
//  AppFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    
    // MARK: - State
    
    @ObservableState
    enum State: Equatable {
        case onboarding(OnboardingFeature.State)
        case signUp(SignUpFeature.State)
        case home(MembershipStatus)
    }
    
    // MARK: - Action
    
    enum Action {
        case onboarding(OnboardingFeature.Action)
        case signUp(SignUpFeature.Action)
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onboarding(.delegate(.signedIn(user))):
                state = .home(.member(user))
                return .none

            case let .onboarding(.delegate(.needsSignUp(user, fullName))):
                state = .signUp(SignUpFeature.State(user: user, fullName: fullName))
                return .none

            case .onboarding(.delegate(.browseWithoutSignUp)):
                state = .home(.guest)
                return .none

            case let .signUp(.delegate(.completed(user))):
                state = .home(.member(user))
                return .none

            case .onboarding, .signUp:
                return .none
            }
        }
        .ifCaseLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifCaseLet(\.signUp, action: \.signUp) {
            SignUpFeature()
        }
    }
}
