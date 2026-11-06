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

        var canWithdraw: Bool {
            selectedReason != nil && !isWithdrawing
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

    @Dependency(\.appleAuthClient) var appleAuthClient
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

            case let .reasonTapped(reason):
                state.selectedReason = reason
                return .none

            case let .detailChanged(detail):
                state.detail = String(detail.prefix(Self.maximumDetailLength))
                return .none

            case .withdrawButtonTapped:
                guard state.canWithdraw else { return .none }

                state.isWithdrawing = true
                return fetchAuthorizationCode()

            case let .authorizationCodeResponse(.success(authorizationCode)):
                guard let reason = state.selectedReason else {
                    state.isWithdrawing = false
                    return .none
                }

                return withdraw(reason: reason, detail: state.detail, authorizationCode: authorizationCode)

            case let .authorizationCodeResponse(.failure(error)):
                state.isWithdrawing = false
                guard (error as? AppleSignInError) != .canceled else { return .none }

                state.alert = .make(.withdrawalFailed)
                return .none

            case .withdrawResponse(.success):
                state.isWithdrawing = false
                state.alert = .make(.withdrawalCompleted, confirm: .confirm)
                return .none

            case .withdrawResponse(.failure):
                state.isWithdrawing = false
                state.alert = .make(.withdrawalFailed)
                return .none

            case .alert(.presented(.confirm)):
                return .send(.delegate(.withdrawn))

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
                try await appleAuthClient.fetchAuthorizationCode()
            }))
        }
    }

    private func withdraw(
        reason: WithdrawalReason,
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
