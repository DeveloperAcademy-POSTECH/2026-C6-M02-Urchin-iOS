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
        var currentPageIndex: Int {
            OnboardingPage.allCases.firstIndex(of: currentPage) ?? 0
        }
        var nonce: String?
        var isSigningIn = false
        var pendingFullName: String?
        @Presents var alert: AlertState<Action.Alert>?
        
        var hashedNonce: String? {
            nonce.map(AppleNonce.sha256)
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case onAppear
        case timerTicked
        case screenTapped
        case appleButtonTapped
        case browseButtonTapped
        case signInAppleCompleted(Result<AppleCredential, AppleSignInError>)
        case signInResponse(Result<SignInResult, any Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case confirm
        }

        enum Delegate {
            case signedIn(AuthUser)
            case needsSignUp(AuthUser, fullName: String?)
            case browseWithoutSignUp
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.authClient) var authClient
    
    // MARK: - Body
    
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
                state.nonce = UUID().uuidString
                return .none
                
            case .browseButtonTapped:
                return .send(.delegate(.browseWithoutSignUp))
                
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
                state.pendingFullName = credential.fullName ?? state.pendingFullName

                let fullName = state.pendingFullName

                return .run { send in
                    await send(.signInResponse(Result {
                        let user = try await authClient.signInWithApple(credential.idToken, nonce)
                        let isMember = try await authClient.fetchIsMember(user.id)

                        return isMember ? .member(user) : .newUser(user, fullName: fullName)
                    }))
                }
                .cancellable(id: CancelID.signIn, cancelInFlight: true)
                
            case let .signInResponse(.success(.member(user))):
                state.isSigningIn = false
                state.nonce = nil
                state.pendingFullName = nil
                return .send(.delegate(.signedIn(user)))

            case let .signInResponse(.success(.newUser(user, fullName))):
                state.isSigningIn = false
                state.nonce = nil
                state.pendingFullName = nil
                return .send(.delegate(.needsSignUp(user, fullName: fullName)))

            case .signInResponse(.failure):
                state.isSigningIn = false
                state.nonce = nil
                state.alert = AlertState.make(.signInFailed)
                return .none

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension OnboardingFeature {
    
    private nonisolated enum CancelID {
        case signIn
        case timer
    }
    
    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in await clock.timer(interval: .seconds(3)) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }
}
