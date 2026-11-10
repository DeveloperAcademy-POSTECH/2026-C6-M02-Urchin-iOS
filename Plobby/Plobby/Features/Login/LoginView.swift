//
//  LoginView.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import SwiftUI

import ComposableArchitecture

struct LoginView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<LoginFeature>

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            title
                .frame(maxHeight: .infinity, alignment: .center)

            buttons
        }
        .background {
            Image(.loginBackground)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
        }
        .background(Color(.gray0))
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
    }
}

// MARK: - 로고

extension LoginView {

    private var title: some View {
        VStack(alignment: .center, spacing: 16.scaled) {
            Image(.homeLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 182.scaled)
                .accessibilityLabel("plobby")

            Text("혼자가 아닌, 함께 지키는 바다")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textPrimary))
        }
    }
}

// MARK: - 로그인 버튼

extension LoginView {

    private var buttons: some View {
        VStack(alignment: .center, spacing: 0) {
            Button {
                store.send(.signIn(.appleSignInRequested))
            } label: {
                AppleLoginLabel()
            }
            .buttonStyle(.plain)
            .disabled(store.signIn.isSigningIn)

            Button {
                store.send(.browseButtonTapped)
            } label: {
                Text("회원가입 없이 둘러보기")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.gray700))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48.scaled)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 34.scaled)
    }
}
