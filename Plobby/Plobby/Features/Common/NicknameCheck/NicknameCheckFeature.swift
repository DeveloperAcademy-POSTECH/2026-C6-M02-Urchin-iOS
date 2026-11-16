//
//  NicknameCheckFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct NicknameCheckFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let originalNickname: String?
        var nickname: String
        var isChecking = false
        var isAvailable: Bool?
        var checkedNickname: String?
        var isOverLimit = false
        @Presents var alert: AlertState<Action.Alert>?

        init(originalNickname: String? = nil) {
            self.originalNickname = originalNickname
            self.nickname = originalNickname ?? ""
        }

        var isChanged: Bool {
            nickname != originalNickname
        }

        var isChecked: Bool {
            isAvailable == true
        }

        var isFormatInvalid: Bool {
            !nickname.isEmpty && !Nickname.isValid(nickname)
        }

        var hasError: Bool {
            isFormatInvalid || isOverLimit || isAvailable == false
        }

        var canCheck: Bool {
            isChanged && Nickname.isValid(nickname) && !isOverLimit && !isChecking && !isChecked
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case checkButtonTapped
        case checkResponse(Result<Bool, any Error>)
        case alert(PresentationAction<Alert>)

        enum Alert {
            case confirm
        }
    }

    // MARK: - Dependency

    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.nickname):
                state.isOverLimit = state.nickname.count > Nickname.maximumLength
                if state.isOverLimit {
                    state.nickname = String(state.nickname.prefix(Nickname.maximumLength))
                }

                guard state.nickname != state.checkedNickname else { return .none }

                state.isChecking = false
                state.isAvailable = nil
                state.checkedNickname = nil
                return .cancel(id: CancelID.check)

            case .checkButtonTapped:
                guard state.canCheck else { return .none }

                state.isChecking = true
                return check(state.nickname)

            case let .checkResponse(.success(isAvailable)):
                state.isChecking = false
                state.isAvailable = isAvailable
                state.checkedNickname = state.nickname
                return .none

            case let .checkResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isChecking = false
                state.alert = .make(.nicknameCheckFailed)
                return .none

            case .binding, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension NicknameCheckFeature {

    private nonisolated enum CancelID {
        case check
    }

    private func check(_ nickname: String) -> Effect<Action> {
        .run { send in
            await send(.checkResponse(Result {
                try await userClient.fetchIsNicknameAvailable(nickname)
            }))
        }
        .cancellable(id: CancelID.check, cancelInFlight: true)
    }
}
