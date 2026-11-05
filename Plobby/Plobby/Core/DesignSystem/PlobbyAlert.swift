//
//  PlobbyAlert.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import SwiftUI

import ComposableArchitecture

/// 디자인 시스템 Alert. `AlertState`의 버튼을 순서대로 그리고, 마지막 버튼을 주요 동작으로 강조해요.
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
                .background(isPrimary ? Color(.green600) : Color(.gray200), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation

extension View {

    /// 시스템 `.alert` 대신 화면을 어둡게 덮고 가운데에 `PlobbyAlert`를 띄워요.
    func plobbyAlert<Action>(_ item: Binding<Store<AlertState<Action>, Action>?>) -> some View {
        overlay {
            if let store = item.wrappedValue {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    PlobbyAlert(state: store.withState { $0 }) { button in
                        // 동작이 있으면 보내고(보낸 뒤 자동으로 닫혀요), 없으면 그냥 닫아요.
                        button.withAction { action in
                            if let action {
                                store.send(action)
                            } else {
                                item.wrappedValue = nil
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: item.wrappedValue != nil)
    }
}
