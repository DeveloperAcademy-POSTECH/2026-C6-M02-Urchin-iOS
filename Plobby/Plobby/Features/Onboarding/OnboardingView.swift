//
//  OnboardingView.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import AuthenticationServices
import SwiftUI

import ComposableArchitecture

struct OnboardingView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<OnboardingFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            pageContent
            appleLoginButton
            browseButton
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Subviews

extension OnboardingView {
    
    private var pageContent: some View {
        VStack(alignment: .center, spacing: 0) {
            indicator

            Spacer()

            pageDescription
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.screenTapped)
        }
    }
    
    private var indicator: some View {
        OnboardingPageIndicator(
            currentIndex: store.currentPageIndex,
            pageCount: OnboardingPage.allCases.count
        )
        .padding(.top, 20)
        .padding(.horizontal, 65)
    }
    
    private var pageDescription: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(store.currentPage.title)
                .font(.system(size: 28, weight: .bold))
            
            Text(store.currentPage.description)
                .font(.system(size: 16, weight: .regular))
        }
        .multilineTextAlignment(.center)
        .animation(.easeInOut(duration: 0.3), value: store.currentPage)
        .padding(.horizontal, 20)
        .padding(.bottom, 77)
    }
    
    private var appleLoginButton: some View {
        SignInWithAppleButton(.signIn) { request in
            store.send(.appleButtonTapped)
            request.requestedScopes = [.fullName]
            request.nonce = store.hashedNonce
        } onCompletion: { result in
            store.send(.signInAppleCompleted(result.appleCredential))
        }
        .frame(height: 51)
        .overlay {
            AppleLoginLabel()
                .allowsHitTesting(false)
        }
        .disabled(store.isSigningIn)
        .padding(.horizontal, 38.5)
        .padding(.bottom, 17)
    }
    
    private var browseButton: some View {
        Button {
            store.send(.browseButtonTapped)
        } label: {
            Text("회원가입 없이 둘러보기")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.gray)
        }
        .padding(.bottom, 17)
    }
}

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
