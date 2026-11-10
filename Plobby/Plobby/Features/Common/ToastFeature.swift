//
//  ToastFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import ComposableArchitecture

@Reducer
struct ToastFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var toastType: ToastType?
    }

    // MARK: - Action

    enum Action {
        case show(ToastType)
        case toastDismissed
    }

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock

    // MARK: - body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .show(toastType):
                state.toastType = toastType
                return dismissAfterDelay()

            case .toastDismissed:
                state.toastType = nil
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
