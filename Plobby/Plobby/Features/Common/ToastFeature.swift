//
//  ToastFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import ComposableArchitecture

/// 잠시 떴다가 사라지는 안내 문구.
/// 부모 Feature에 Scope로 붙이고 `.send(.toast(.show("…")))`로 띄워요.
@Reducer
struct ToastFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var toastMessage: String?
    }

    // MARK: - Action

    enum Action {
        case show(String)
        case toastDismissed
    }

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock

    // MARK: - body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .show(message):
                state.toastMessage = message
                return dismissAfterDelay()

            case .toastDismissed:
                state.toastMessage = nil
                return .none
            }
        }
    }
}

// MARK: - Constants

extension ToastFeature {

    static let toastDuration: Duration = .seconds(2)
}

// MARK: - Functions

private extension ToastFeature {

    nonisolated enum CancelID {
        case toast
    }

    func dismissAfterDelay() -> Effect<Action> {
        .run { send in
            try await clock.sleep(for: Self.toastDuration)
            await send(.toastDismissed)
        }
        .cancellable(id: CancelID.toast, cancelInFlight: true)
    }
}
