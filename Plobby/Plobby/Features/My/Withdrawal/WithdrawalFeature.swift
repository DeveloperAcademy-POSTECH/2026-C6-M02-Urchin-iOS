//
//  WithdrawalFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct WithdrawalFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedReason: WithdrawalReason?
        var detail = ""
        var isWithdrawing = false
        @Presents var alert: AlertState<Action.Alert>?

        var detailCount: Int {
            detail.count
        }

        var hasDetail: Bool {
            !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var canWithdraw: Bool {
            (selectedReason != nil || hasDetail) && !isWithdrawing
        }
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case reasonTapped(WithdrawalReason)
        case detailChanged(String)
        case withdrawButtonTapped
        case authorizationCodeResponse(Result<String, any Error>)
        case withdrawResponse(Result<Void, any Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case confirm
        }

        enum Delegate {
            case withdrawn
        }
    }

    // MARK: - Dependency

    @Dependency(\.authClient) var authClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            // 탈퇴를 처리하는 동안 사유와 의견이 바뀌면, 인증 응답 뒤 보내는 탈퇴 요청에 바뀐 값이 섞여요.
            // 화면에서도 입력을 막지만, 어떤 경로로 들어와도 여기서 한 번 더 막아요.
            case let .reasonTapped(reason):
                guard !state.isWithdrawing else { return .none }

                state.selectedReason = state.selectedReason == reason ? nil : reason
                state.detail = ""
                return .none

            case let .detailChanged(detail):
                guard !state.isWithdrawing else { return .none }

                state.detail = String(detail.prefix(Self.maximumDetailLength))
                if state.hasDetail {
                    state.selectedReason = nil
                }
                return .none

            case .withdrawButtonTapped:
                guard state.canWithdraw else { return .none }

                state.isWithdrawing = true
                return fetchAuthorizationCode()

            case let .authorizationCodeResponse(.success(authorizationCode)):
                return withdraw(
                    reason: state.selectedReason,
                    detail: state.detail,
                    authorizationCode: authorizationCode
                )

            case let .authorizationCodeResponse(.failure(error)):
                state.isWithdrawing = false
                guard (error as? AppleSignInError) != .canceled else { return .none }

                state.alert = .make(.withdrawalFailed)
                return .none

            case .withdrawResponse(.success):
                @Shared(.recentSearches) var recentSearches
                $recentSearches.withLock { $0.removeAll() }

                state.isWithdrawing = false
                state.alert = .make(.withdrawalCompleted, confirm: .confirm)
                return .none

            case .withdrawResponse(.failure):
                state.isWithdrawing = false
                state.alert = .make(.withdrawalFailed)
                return .none

            case .alert(.presented(.confirm)):
                return .run { send in
                    try? await authClient.signOut(nil)
                    await send(.delegate(.withdrawn))
                }

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Constant

extension WithdrawalFeature {

    static let maximumDetailLength = 500
}

// MARK: - Functions

extension WithdrawalFeature {

    private func fetchAuthorizationCode() -> Effect<Action> {
        .run { send in
            await send(.authorizationCodeResponse(Result {
                try await authClient.fetchAppleAuthorizationCode()
            }))
        }
    }

    private func withdraw(
        reason: WithdrawalReason?,
        detail: String,
        authorizationCode: String
    ) -> Effect<Action> {
        .run { send in
            await send(.withdrawResponse(Result {
                try await authClient.withdraw(reason, detail, authorizationCode)
            }))
        }
    }
}
