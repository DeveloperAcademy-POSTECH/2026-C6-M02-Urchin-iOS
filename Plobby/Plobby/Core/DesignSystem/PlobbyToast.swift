//
//  PlobbyToast.swift
//  Plobby
//
//  Created by 이은지 on 11/7/26.
//

import SwiftUI

/// 토스트 메시지 UI
/// - 보통은 `.plobbyToast(_:action:)`로 화면에 붙여 사용합니다.
///
struct PlobbyToast: View {

    // MARK: - Properties

    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 16.scaled) {
            Text(message)
                .plobbyFont(.body)
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity, alignment: actionTitle == nil ? .center : .leading)
                .accessibilityAddTraits(.isStaticText)

            if let actionTitle, let action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .plobbyFont(.actionLabel)
                        .foregroundStyle(Color(.gray0))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24.scaled)
        .padding(.vertical, 16.scaled)
        .background(Color(.gray900), in: RoundedRectangle(cornerRadius: 8.scaled))
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 19.scaled)
    }
}

// MARK: - Modifier

extension View {

    /// 토스트 종류에 버튼 문구가 있으면 오른쪽에 버튼을 보여주고, 누르면 'action'을 실행
    func plobbyToast(_ toastType: ToastType?, action: (() -> Void)? = nil) -> some View {
        overlay(alignment: .bottom) {
            if let toastType {
                PlobbyToast(message: toastType.message, actionTitle: toastType.actionTitle, action: action)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toastType)
    }
}
