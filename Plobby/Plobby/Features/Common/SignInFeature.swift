//
//  SignInFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct SignInFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var nonce: String?
        var isSigningIn = false
        var pendingFullName: String?
        @Presents var alert: AlertState<Action.Alert>?
    }

    // MARK: - Action

    enum Action {
        case appleSignInRequested
        case appleCredentialResponse(Result<AppleCredential, AppleSignInError>)
        case signInResponse(Result<SignInResult, any Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case confirm
        }

        enum Delegate {
            case signedIn(AuthUser)
            case needsSignUp(AuthUser, fullName: String?)
        }
    }

    // MARK: - Dependency

    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .appleSignInRequested:
                guard !state.isSigningIn, state.nonce == nil else { return .none }

                let nonce = UUID().uuidString
                state.nonce = nonce
                return fetchAppleCredential(hashedNonce: AppleNonce.sha256(nonce))

            case .appleCredentialResponse(.failure(.canceled)):
                state.nonce = nil
                return .none

            case .appleCredentialResponse(.failure):
                state.nonce = nil
                state.alert = .make(.signInFailed)
                return .none

            case let .appleCredentialResponse(.success(credential)):
                state.pendingFullName = credential.fullName ?? state.pendingFullName

                guard let nonce = state.nonce else {
                    state.alert = .make(.signInFailed)
                    return .none
                }

                state.isSigningIn = true
                return signIn(idToken: credential.idToken, nonce: nonce, fullName: state.pendingFullName)

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

extension SignInFeature {

    private func fetchAppleCredential(hashedNonce: String) -> Effect<Action> {
        .run { send in
            await send(.appleCredentialResponse(await authClient.fetchCredential(hashedNonce)))
        }
    }

    private func signIn(idToken: String, nonce: String, fullName: String?) -> Effect<Action> {
        .run { send in
            await send(.signInResponse(Result {
                let user = try await authClient.signInWithApple(idToken, nonce, fullName)

                do {
                    let profile = try await userClient.fetchMyProfile()

                    return profile != nil ?
                        .member(user) :
                        .newUser(user, fullName: user.fullName)
                } catch {
                    try? await authClient.signOut(nil)
                    throw error
                }
            }))
        }
    }
}
