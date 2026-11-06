//
//  SettingsFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct SettingsFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let appVersion: String
        var isNotificationEnabled = true
        var isSigningOut = false
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var withdrawal: WithdrawalFeature.State?
        @Presents var blockedUsers: BlockedUsersFeature.State?

        init(appVersion: String? = nil) {
            self.appVersion = appVersion ?? Bundle.main.appVersion
        }
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case notificationToggled(Bool)
        case manageUserTapped
        case logoutButtonTapped
        case withdrawalButtonTapped
        case signOutResponse(Result<Void, any Error>)
        case alert(PresentationAction<Alert>)
        case withdrawal(PresentationAction<WithdrawalFeature.Action>)
        case blockedUsers(PresentationAction<BlockedUsersFeature.Action>)
        case delegate(Delegate)

        enum Alert {
            case confirmLogout
            case confirmWithdrawal
        }

        enum Delegate {
            case signedOut
        }
    }

    // MARK: - Dependency

    @Dependency(\.authClient) var authClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.pushClient) var pushClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            // TODO: 알림 수신 여부를 서버에 저장
            case let .notificationToggled(isEnabled):
                state.isNotificationEnabled = isEnabled
                return .none
                
            case .manageUserTapped:
                state.blockedUsers = BlockedUsersFeature.State()
                return .none

            case .logoutButtonTapped:
                state.alert = .make(.logoutConfirm, confirm: .confirmLogout)
                return .none

            case .withdrawalButtonTapped:
                state.alert = .make(.withdrawalConfirm, cancel: .confirmWithdrawal)
                return .none

            case .alert(.presented(.confirmLogout)):
                guard !state.isSigningOut else { return .none }

                state.isSigningOut = true
                return signOut()

            case .alert(.presented(.confirmWithdrawal)):
                state.withdrawal = WithdrawalFeature.State()
                return .none

            case .signOutResponse(.success):
                state.isSigningOut = false
                return .send(.delegate(.signedOut))

            case .signOutResponse(.failure):
                state.isSigningOut = false
                state.alert = .make(.logoutFailed)
                return .none

            case .withdrawal(.presented(.delegate(.withdrawn))):
                return .send(.delegate(.signedOut))

            case .alert, .withdrawal, .blockedUsers, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$withdrawal, action: \.withdrawal) {
            WithdrawalFeature()
        }
        .ifLet(\.$blockedUsers, action: \.blockedUsers) {
            BlockedUsersFeature()
        }
    }
}

// MARK: - Functions

extension SettingsFeature {

    private func signOut() -> Effect<Action> {
        .run { send in
            let token = try? await pushClient.fetchToken()

            await send(.signOutResponse(Result {
                try await authClient.signOut(token)
            }))
        }
    }
}

// MARK: - Bundle+

private extension Bundle {

    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}
