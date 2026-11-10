//
//  NicknameCheckFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import Foundation

import ComposableArchitecture

/// 회원가입과 프로필 수정에서 함께 쓰는 닉네임 입력과 중복 확인이에요.
/// 원래 닉네임이 있으면(프로필 수정) 그 닉네임과 달라야 확인할 수 있어요.
@Reducer
struct NicknameCheckFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let originalNickname: String?
        var nickname: String
        var isChecking = false
        var isAvailable: Bool?
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
            isFormatInvalid || isAvailable == false
        }

        var canCheck: Bool {
            isChanged && Nickname.isValid(nickname) && !isChecking && !isChecked
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
            // 입력창이 nickname을 바꾸면 최대 글자 수로 자르고, 이전 확인 결과는 지워요
            case .binding(\.nickname):
                state.nickname = String(state.nickname.prefix(Nickname.maximumLength))
                state.isChecking = false
                state.isAvailable = nil
                return .cancel(id: CancelID.check)

            case .checkButtonTapped:
                guard state.canCheck else { return .none }

                state.isChecking = true
                return check(state.nickname)

            case let .checkResponse(.success(isAvailable)):
                state.isChecking = false
                state.isAvailable = isAvailable
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

    /// 진행 중인 중복 확인 요청을 가리키는 이름표예요.
    /// 닉네임이 바뀌면 이 이름표로 요청을 취소해서, 늦게 온 이전 닉네임의 결과가 반영되지 않게 해요.
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
