//
//  LoginRequiredSheet.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import SwiftUI

struct LoginRequiredSheet: View {

    // MARK: - Properties

    private static let designHeight: CGFloat = 279

    var isSigningIn = false
    let onAppleLogin: () -> Void
    let onBrowse: () -> Void

    // MARK: - Body
    
    var body: some View {
        content
            .presentationDetents([.height(Self.designHeight.scaled)])
            .presentationBackgroundInteraction(.enabled)
    }
}

// MARK: - Subviews

private extension LoginRequiredSheet {
    
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            message

            Spacer()

            appleLoginButton
            browseButton
        }
    }
    
    var title: some View {
        VStack(spacing: 0) {
            Text("로그인하고 내 활동을 기록해보세요")
                .plobbyFont(.metric)
                .foregroundStyle(Color(.textPrimary))
                .padding(.horizontal, 24.scaled)
                .padding(.top, 30.scaled)
                .padding(.bottom, 8.scaled)
        }
    }
    
    var message: some View {
        VStack(spacing: 0) {
            Text("로그인 후 다른 사람들의 기록 보기, 알림을 볼 수 있어요.")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24.scaled)
        }
    }

    var appleLoginButton: some View {
        Button(action: onAppleLogin) {
            AppleLoginLabel()
        }
        .disabled(isSigningIn)
        .padding(.horizontal, 20.scaled)
    }

    var browseButton: some View {
        Button(action: onBrowse) {
            Text("둘러보기")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17.scaled)
        }
    }
}
