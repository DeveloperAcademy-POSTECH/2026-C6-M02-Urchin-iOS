//
//  SignUpFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct SignUpFeature {

    // MARK: - Path

    @Reducer
    enum Path {
        case profileSetup(ProfileSetupFeature)
        case favoriteBeachSetup(FavoriteBeachSetupFeature)
        case complete(SignUpCompleteFeature)
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let user: AuthUser
        var termsAgreement = TermsAgreementFeature.State()
        var path = StackState<Path.State>()
        var isSigningUp = false
        @Presents var alert: AlertState<Action.Alert>?
    }

    // MARK: - Action

    enum Action {
        case termsAgreement(TermsAgreementFeature.Action)
        case path(StackActionOf<Path>)
        case signUpResponse(Result<Void, any Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case confirm
        }

        enum Delegate {
            case completed(AuthUser)
        }
    }

    // MARK: - Dependency

    @Dependency(\.authClient) var authClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.termsAgreement, action: \.termsAgreement) {
            TermsAgreementFeature()
        }

        Reduce { state, action in
            switch action {
            case .termsAgreement(.nextButtonTapped):
                guard state.termsAgreement.isAllAgreed else { return .none }

                state.path.append(.profileSetup(ProfileSetupFeature.State()))
                return .none

            case let .path(.element(id: id, action: .profileSetup(.nextButtonTapped))):
                guard state.path[id: id]?.profileSetup?.canGoNext == true else { return .none }

                state.path.append(.favoriteBeachSetup(FavoriteBeachSetupFeature.State()))
                return .none

            case let .path(.element(id: id, action: .favoriteBeachSetup(.signUpButtonTapped))):
                guard
                    !state.isSigningUp,
                    let profile = state.path.lazy.compactMap(\.profileSetup).first,
                    let favoriteBeach = state.path[id: id]?.favoriteBeachSetup
                else { return .none }

                state.isSigningUp = true
                return signUp(SignUpProfile(
                    userID: state.user.id,
                    profileImage: profile.profileImage,
                    nickname: profile.nickname,
                    favoriteBeachIDs: favoriteBeach.picker.selectedBeachIDs
                ))

            case .signUpResponse(.success):
                state.isSigningUp = false
                state.path.append(.complete(SignUpCompleteFeature.State()))
                return .none

            case .signUpResponse(.failure):
                state.isSigningUp = false
                state.alert = .make(.signUpFailed)
                return .none

            case .path(.element(id: _, action: .complete(.completeButtonTapped))):
                return .send(.delegate(.completed(state.user)))

            case .termsAgreement, .path, .alert, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

private extension SignUpFeature {

    func signUp(_ profile: SignUpProfile) -> Effect<Action> {
        .run { send in
            await send(.signUpResponse(Result {
                try await authClient.signUp(profile)
            }))
        }
    }
}

// MARK: - Conformance

extension SignUpFeature.Path.State: Equatable {}
