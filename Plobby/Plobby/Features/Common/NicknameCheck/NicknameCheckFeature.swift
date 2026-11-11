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
        /// 중복 확인을 마친 닉네임이에요. 입력창을 다시 눌러 같은 값이 들어와도 결과를 지키려고 기억해요.
        var checkedNickname: String?
        /// 10자를 넘겨 잘린 직후예요. 활동 메모처럼 안내 문구를 보여주고 중복 확인을 막아요.
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
            // 활동 메모처럼 10자를 넘기면 10자로 자르고, 안내 문구를 보여주면서 중복 확인을 막아요.
            // 확인한 닉네임과 달라졌을 때만 이전 결과를 지워요. 입력창에 포커스만 줘도 같은 값이 다시 들어오기 때문이에요.
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
