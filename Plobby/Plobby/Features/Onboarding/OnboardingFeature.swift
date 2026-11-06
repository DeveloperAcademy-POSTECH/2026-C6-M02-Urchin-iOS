//
//  OnboardingFeature.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var currentPage: OnboardingPage = .trashAmount
        var signIn = SignInFeature.State()
        
        var currentPageIndex: Int {
            OnboardingPage.allCases.firstIndex(of: currentPage) ?? 0
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case timerTicked
        case screenTapped
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
            case .onAppear:
                return startTimer()

            case .timerTicked:
                state.currentPage = state.currentPage.next
                return .none

            case .screenTapped:
                state.currentPage = state.currentPage.next
                return startTimer()
                
            case .browseButtonTapped:
                guard !state.signIn.isSigningIn else { return .none }
                
                return .send(.delegate(.browseWithoutSignUp))
                
            case .signIn, .delegate:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension OnboardingFeature {
    
    private nonisolated enum CancelID {
        case timer
    }
    
    private static let pageInterval: Duration = .seconds(3)
    
    private func startTimer() -> Effect<Action> {
        .timer(
            id: CancelID.timer,
            interval: OnboardingFeature.pageInterval,
            action: .timerTicked
        )
    }
}
