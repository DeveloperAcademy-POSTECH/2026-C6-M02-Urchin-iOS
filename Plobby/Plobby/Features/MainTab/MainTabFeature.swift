//
//  MainTabFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct MainTabFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
        @Presents var recordFlow: RecordFlowFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var selectedTab: MainTab = .home
        var isRecordMenuPresented = false
        var isLoginSheetPresented = false
        var isSigningIn = false
        var nonce: String?
        var home: HomeFeature.State
        var map = MapFeature.State()
        var my = MyFeature.State()
    }
    
    // MARK: - Action
    
    enum Action {
        case tabSelected(MainTab)
        case recordMenuDismissed
        case recordTypeSelected(RecordType)
        case loginSheetPresentationChanged(Bool)
        case appleLoginButtonTapped
        case appleCredentialResponse(Result<AppleCredential, AppleSignInError>)
        case signInResponse(Result<SignInResult, any Error>)
        case home(HomeFeature.Action)
        case map(MapFeature.Action)
        case my(MyFeature.Action)
        case recordFlow(PresentationAction<RecordFlowFeature.Action>)
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

    @Dependency(\.appleSignInClient) var appleSignInClient
    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapFeature()
        }
        Scope(state: \.my, action: \.my) {
            MyFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .recordTypeSelected where state.isGuest:
                state.isRecordMenuPresented = false
                state.isLoginSheetPresented = true
                return .none
                
            case .home(.delegate(.loginRequired)):
                state.isLoginSheetPresented = true
                return .none
                
            case let .loginSheetPresentationChanged(isPresented):
                state.isLoginSheetPresented = isPresented
                return .none

            case .appleLoginButtonTapped:
                guard !state.isSigningIn else { return .none }

                let nonce = UUID().uuidString
                state.nonce = nonce
                state.isLoginSheetPresented = false
                return fetchAppleCredential(hashedNonce: AppleNonce.sha256(nonce))

            case .appleCredentialResponse(.failure(.canceled)):
                state.nonce = nil
                return .none

            case .appleCredentialResponse(.failure):
                state.nonce = nil
                state.alert = .make(.signInFailed)
                return .none

            case let .appleCredentialResponse(.success(credential)):
                guard let nonce = state.nonce else {
                    state.alert = .make(.signInFailed)
                    return .none
                }

                state.isSigningIn = true
                return signIn(idToken: credential.idToken, nonce: nonce, fullName: credential.fullName)

            case let .signInResponse(.success(.member(user))):
                state.isSigningIn = false
                state.nonce = nil
                return .send(.delegate(.signedIn(user)))

            case let .signInResponse(.success(.newUser(user, fullName))):
                state.isSigningIn = false
                state.nonce = nil
                return .send(.delegate(.needsSignUp(user, fullName: fullName)))

            case .signInResponse(.failure):
                state.isSigningIn = false
                state.nonce = nil
                state.alert = .make(.signInFailed)
                return .none
                
            case .tabSelected(.record):
                state.isRecordMenuPresented.toggle()
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                state.isRecordMenuPresented = false
                return .none
                
            case .recordMenuDismissed:
                state.isRecordMenuPresented = false
                return .none
                
            case let .recordTypeSelected(recordType):
                state.isRecordMenuPresented = false
                state.recordFlow = RecordFlowFeature.State(recordType: recordType)
                return .none
                
            case .recordFlow(.presented(.delegate(.closed))):
                state.recordFlow = nil
                return .none
                
            case .recordFlow(.presented(.delegate(.recordDeleted))):
                state.recordFlow = nil
                state.selectedTab = .home
                return .none
                
            case let .home(.delegate(.recordStarted(recordType))):
                return .send(.recordTypeSelected(recordType))
            
            case .home:
                return .none
            
            case .map:
                return .none
            
            case .my:
                return .none
            
            case .recordFlow, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$recordFlow, action: \.recordFlow) {
            RecordFlowFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension MainTabFeature {

    private static let sheetDismissDelay: Duration = .milliseconds(350)

    private func fetchAppleCredential(hashedNonce: String) -> Effect<Action> {
        .run { send in
            try await clock.sleep(for: Self.sheetDismissDelay)
            await send(.appleCredentialResponse(await appleSignInClient.fetchCredential(hashedNonce)))
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

// MARK: - State

private extension MainTabFeature.State {

    var isGuest: Bool {
        if case .guest = membershipStatus { true } else { false }
    }
}
