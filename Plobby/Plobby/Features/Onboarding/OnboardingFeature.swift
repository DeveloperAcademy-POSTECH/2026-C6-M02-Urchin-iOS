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
        var nonce: String?
        var isSigningIn = false
        var pendingFullName: String?
        @Presents var alert: AlertState<Action.Alert>?
        
        var currentPageIndex: Int {
            OnboardingPage.allCases.firstIndex(of: currentPage) ?? 0
        }
        
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
                guard !state.isSigningIn else { return .none }
                
                return .send(.delegate(.browseWithoutSignUp))
                
            case .signInAppleCompleted(.failure(.canceled)):
                state.nonce = nil
                return .none
                
            case .signInAppleCompleted(.failure):
                state.nonce = nil
                state.alert = .make(.signInFailed)
                return .none
                
            case let .signInAppleCompleted(.success(credential)):
                state.pendingFullName = credential.fullName ?? state.pendingFullName
                
                guard let nonce = state.nonce else {
                    state.alert = .make(.signInFailed)
                    return .none
                }
                
                state.isSigningIn = true
                
                return signIn(
                    idToken: credential.idToken,
                    nonce: nonce,
                    fullName: state.pendingFullName
                )
                
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
                state.alert = .make(.signInFailed)
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
        case timer
    }
    
    private static let pageInterval: Duration = .seconds(3)
    
    private func signIn(
        idToken: String,
        nonce: String,
        fullName: String?
    ) -> Effect<Action> {
        .run { send in
            await send(.signInResponse(Result {
                let user = try await authClient.signInWithApple(idToken, nonce, fullName)
                
                do {
                    let isMember = try await authClient.fetchIsMember(user.id)
                    
                    return isMember ?
                        .member(user) :
                        .newUser(user, fullName: user.fullName)
                } catch {
                    try? await authClient.signOut()
                    throw error
                }
            }))
        }
    }
    
    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in await clock.timer(interval: OnboardingFeature.pageInterval) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }
}
