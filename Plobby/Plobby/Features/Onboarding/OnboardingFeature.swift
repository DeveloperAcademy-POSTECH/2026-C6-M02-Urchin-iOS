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
        var nonce: String?
        var isSigningIn = false
        var user: AuthUser?
        @Presents var alert: AlertState<Action.Alert>?
        
        var hashedNonce: String? {
            nonce.map(AppleNonce.sha256)
        }
    }
    
    enum Action {
        case appleButtonTapped
        case signInAppleCompleted(Result<AppleCredential, AppleSignInError>)
        case signInResponse(Result<AuthUser, any Error>)
        case alert(PresentationAction<Alert>)
        
        enum Alert {
            case confirm
        }
    }
    
    @Dependency(\.authClient) var authClient
    
    private nonisolated enum CancelID {
        case signIn
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .appleButtonTapped:
                state.nonce = UUID().uuidString
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
