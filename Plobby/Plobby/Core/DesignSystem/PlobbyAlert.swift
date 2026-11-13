//
//  PlobbyAlert.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import SwiftUI

import ComposableArchitecture

struct PlobbyAlert<Action>: View {

    // MARK: - Properties

    let state: AlertState<Action>
    let buttonTapped: (ButtonState<Action>) -> Void

    private static var width: CGFloat { 309 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(state.title)
                    .plobbyFont(.cardTitle)

                if let message = state.message {
                    Text(message)
                        .plobbyFont(.body)
                }
            }
            .foregroundStyle(Color(.textPrimary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(state.buttons) { button in
                    alertButton(button, isPrimary: button.id == state.buttons.last?.id)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(width: Self.width)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8))
    }

    private func alertButton(_ button: ButtonState<Action>, isPrimary: Bool) -> some View {
        Button {
            buttonTapped(button)
        } label: {
            Text(button.label)
                .plobbyFont(.actionLabel)
                .foregroundStyle(isPrimary ? Color(.gray0) : Color(.textPrimary))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isPrimary ? Color(.primary600) : Color(.gray200), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation

extension View {

    func plobbyAlert<State: ObservableState, Action, AlertAction>(
        store: Store<State, Action>,
        state: KeyPath<State, AlertState<AlertAction>?>,
        action: CaseKeyPath<Action, PresentationAction<AlertAction>>
    ) -> some View {
        let alert = store.state[keyPath: state]

        return overlay {
            if let alert {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    PlobbyAlert(state: alert) { button in
                        button.withAction { alertAction in
                            if let alertAction {
                                store.send(action(.presented(alertAction)))
                            } else {
                                store.send(action(.dismiss))
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: alert != nil)
    }
}
