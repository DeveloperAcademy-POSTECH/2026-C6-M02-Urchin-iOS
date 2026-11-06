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
        @Shared(.isPushEnabled) var isPushEnabled
        var isNotificationEnabled = false
        var isSigningOut = false
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var withdrawal: WithdrawalFeature.State?

        init(appVersion: String? = nil) {
            self.appVersion = appVersion ?? Bundle.main.appVersion
        }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case backButtonTapped
        case notificationToggled(Bool)
        case notificationStatusResponse(PushAuthorization)
        case logoutButtonTapped
        case withdrawalButtonTapped
        case signOutResponse(Result<Void, any Error>)
        case alert(PresentationAction<Alert>)
        case withdrawal(PresentationAction<WithdrawalFeature.Action>)
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
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.pushClient) var pushClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return fetchNotificationStatus()

            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case let .notificationToggled(isEnabled):
                state.isNotificationEnabled = isEnabled

                guard isEnabled else {
                    state.$isPushEnabled.withLock { $0 = false }
                    return disablePush()
                }
                return enablePush()

            case let .notificationStatusResponse(authorization):
                state.isNotificationEnabled = authorization == .authorized && state.isPushEnabled
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

            case .alert, .withdrawal, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$withdrawal, action: \.withdrawal) {
            WithdrawalFeature()
        }
    }
}

// MARK: - Functions

extension SettingsFeature {

    private func fetchNotificationStatus() -> Effect<Action> {
        .run { send in
            await send(.notificationStatusResponse(pushClient.fetchAuthorization()))
        }
    }

    /// 권한이 없으면 먼저 요청하고, 이미 거부했으면 iPhone 설정으로 보내요. 허용되면 기기 토큰을 등록해요.
    private func enablePush() -> Effect<Action> {
        .run { [isPushEnabled = Shared(.isPushEnabled)] send in
            var authorization = await pushClient.fetchAuthorization()

            switch authorization {
            case .notDetermined:
                let isGranted = (try? await pushClient.requestAuthorization()) ?? false
                authorization = isGranted ? .authorized : .denied

            case .denied:
                await pushClient.openNotificationSettings()

            case .authorized:
                break
            }

            if authorization == .authorized {
                isPushEnabled.withLock { $0 = true }
            }
            await send(.notificationStatusResponse(authorization))

            guard authorization == .authorized else { return }

            let token = try await pushClient.fetchToken()
            try await notificationClient.submitDeviceToken(token)
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }

    /// 서버에서 이 기기 토큰을 지워서 푸시를 받지 않아요.
    private func disablePush() -> Effect<Action> {
        .run { _ in
            let token = try await pushClient.fetchToken()
            try await notificationClient.removeDeviceToken(token)
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }

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
