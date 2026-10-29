//
//  LoginTestView.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import AuthenticationServices
import ComposableArchitecture

import SwiftUI

struct LoginTestView: View {
    @Bindable var store: StoreOf<OnboardingFeature>
    
    var body: some View {
        VStack(spacing: 16) {
            if let user = store.user {
                Text("로그인됨: \(user.email ?? user.id.uuidString)")
            }

            SignInWithAppleButton (.signIn) { request in
                store.send(.appleButtonTapped)
                request.requestedScopes = [.fullName]
                request.nonce = store.hashedNonce
            } onCompletion: { result in
                store.send(.signInAppleCompleted(result.appleCredential))
            }
            .fixedSize()
            .disabled(store.isSigningIn)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
