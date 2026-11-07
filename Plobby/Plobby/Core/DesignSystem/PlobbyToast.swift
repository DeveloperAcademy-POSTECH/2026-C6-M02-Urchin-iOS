//
//  PlobbyToast.swift
//  Plobby
//
//  Created by 이은지 on 11/7/26.
//

import SwiftUI

/// 화면 하단에 잠깐 떴다 사라지는 안내 메시지
/// - 보통은 `.plobbyToast(_:)`로 화면에 붙여 써요.
struct PlobbyToast: View {

    // MARK: - Properties

    let message: String

    // MARK: - Body

    var body: some View {
        Text(message)
            .plobbyFont(.body)
            .foregroundStyle(Color(.gray0))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24.scaled)
            .padding(.vertical, 16.scaled)
            .background(Color(.gray900), in: RoundedRectangle(cornerRadius: 8.scaled))
            .padding(.horizontal, 20.scaled)
            .padding(.bottom, 19.scaled)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Modifier

extension View {

    /// `message`가 있으면 하단에 토스트를 띄우고, `nil`이 되면 사라져요
    func plobbyToast(_ message: String?) -> some View {
        overlay(alignment: .bottom) {
            if let message {
                PlobbyToast(message: message)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

#Preview {
    Color(.gray0)
        .plobbyToast("사진은 최대 5장까지 선택할 수 있어요")
}
