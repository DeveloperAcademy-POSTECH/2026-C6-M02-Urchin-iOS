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
    
    @ObservableState
    struct State: Equatable {
        var currentPage: OnboardingPage = .trashAmount
        var currentPageIndex: Int {
            OnboardingPage.allCases.firstIndex(of: currentPage) ?? 0
        }
        var nonce: String?
        var isSigningIn = false
        var user: AuthUser?
        @Presents var alert: AlertState<Action.Alert>?
        
        var hashedNonce: String? {
            nonce.map(AppleNonce.sha256)
        }
    }
    
    enum Action {
        case onAppear
        case timerTicked
        case screenTapped
        case appleButtonTapped
        case browseButtonTapped
        case signInAppleCompleted(Result<AppleCredential, AppleSignInError>)
        case signInResponse(Result<AuthUser, any Error>)
        case alert(PresentationAction<Alert>)
        
        enum Alert {
            case confirm
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.authClient) var authClient
    
    private nonisolated enum CancelID {
        case signIn
        case timer
    }
    
    var body: some Reducer<State, Action> {
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
                
            case .appleButtonTapped:
                return .none
                
            case .browseButtonTapped:
                return .none
                
            case .signInAppleCompleted(.failure(.canceled)):
                state.nonce = nil
                return .none
                
            case .signInAppleCompleted(.failure):
                state.nonce = nil
                state.alert = AlertState.make(.signInFailed)
                return .none
                
            case let .signInAppleCompleted(.success(credential)):
                guard let nonce = state.nonce else {
                    state.alert = AlertState.make(.signInFailed)
                    return .none
                }
                state.isSigningIn = true
                return .run { send in
                    await send(.signInResponse(Result {
                        try await authClient.signInWithApple(credential.idToken, nonce)
                    }))
                }
                .cancellable(id: CancelID.signIn, cancelInFlight: true)
                
            case let .signInResponse(.success(user)):
                state.isSigningIn = false
                state.nonce = nil
                state.user = user
                return .none
                
            case .signInResponse(.failure):
                state.isSigningIn = false
                state.nonce = nil
                state.alert = AlertState.make(.signInFailed)
                return .none
                
            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension OnboardingFeature {
    
    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in await clock.timer(interval: .seconds(3)) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }
}
