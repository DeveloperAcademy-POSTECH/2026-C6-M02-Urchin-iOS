//
//  PlobbyAlert.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import SwiftUI

/// 디자인 시스템의 두 버튼 Alert. 왼쪽은 보조 동작, 오른쪽은 주요 동작이에요.
struct PlobbyAlert: View {

    // MARK: - Properties

    let title: String
    let message: String?
    let secondaryTitle: String
    let primaryTitle: String
    let secondaryAction: () -> Void
    let primaryAction: () -> Void

    private static let width: CGFloat = 309

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(title)
                    .plobbyFont(.cardTitle)

                if let message {
                    Text(message)
                        .plobbyFont(.body)
                }
            }
            .foregroundStyle(Color(.textPrimary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                button(secondaryTitle, foreground: Color(.textPrimary), background: Color(.gray200), action: secondaryAction)
                button(primaryTitle, foreground: Color(.gray0), background: Color(.green600), action: primaryAction)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(width: Self.width)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8))
    }

    private func button(
        _ title: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .plobbyFont(.actionLabel)
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(background, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation

extension View {

    /// 화면을 어둡게 덮고 가운데에 `PlobbyAlert`를 띄워요.
    func plobbyAlert(
        isPresented: Bool,
        title: String,
        message: String? = nil,
        secondaryTitle: String,
        primaryTitle: String,
        secondaryAction: @escaping () -> Void,
        primaryAction: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    PlobbyAlert(
                        title: title,
                        message: message,
                        secondaryTitle: secondaryTitle,
                        primaryTitle: primaryTitle,
                        secondaryAction: secondaryAction,
                        primaryAction: primaryAction
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}
