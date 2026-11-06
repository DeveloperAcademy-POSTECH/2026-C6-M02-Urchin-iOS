//
//  LoginRequiredSheet.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import AuthenticationServices
import SwiftUI

struct LoginRequiredSheet: View {

    // MARK: - Properties

    private static let designHeight: CGFloat = 279

    var isSigningIn = false
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<AppleCredential, AppleSignInError>) -> Void
    let onBrowse: () -> Void

    @State private var scale: CGFloat = 1

    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            let scale = max(proxy.size.width / DesignScale.frameWidth, 0.01)

            content
                .frame(width: DesignScale.frameWidth, height: max(proxy.size.height / scale, 0))
                .scaleEffect(scale, anchor: .topLeading)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width / DesignScale.frameWidth
        } action: { newScale in
            guard newScale > 0 else { return }
            scale = newScale
        }
        .presentationDetents([.height(Self.designHeight * scale)])
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
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .padding(.bottom, 8)
        }
    }
    
    var message: some View {
        VStack(spacing: 0) {
            Text("로그인 후 다른 사람들의 기록 보기, 알림을 볼 수 있어요.")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24)
        }
    }

    var appleLoginButton: some View {
        SignInWithAppleButton(.signIn) { request in
            onAppleRequest(request)
        } onCompletion: { result in
            onAppleCompletion(result.appleCredential)
        }
        .frame(height: 51)
        .overlay {
            AppleLoginLabel()
                .allowsHitTesting(false)
        }
        .disabled(isSigningIn)
        .padding(.horizontal, 20)
    }

    var browseButton: some View {
        Button(action: onBrowse) {
            Text("둘러보기")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
        }
    }
}
