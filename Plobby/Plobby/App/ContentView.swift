//
//  ContentView.swift
//  Plobby
//
//  Created by 더스틴 on 10/22/26.
//

import SwiftUI

import ComposableArchitecture

struct ContentView: View {
    
    // MARK: - Properties
    
    @State private var store = Store(
        initialState: AppFeature.State.launching
    ) {
        AppFeature()
    }

    // MARK: - Body
    
    @State private var isSplashVisible = true

    var body: some View {
        content
            .overlay {
                if isSplashVisible {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isSplashVisible = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .task {
                await store.send(.task).finish()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .launching:
            Color(.gray0)
                .ignoresSafeArea()

        case .onboarding:
            if let store = store.scope(
                state: \.onboarding,
                action: \.onboarding)
            {
                OnboardingView(store: store)
            }

        case .login:
            if let store = store.scope(
                state: \.login,
                action: \.login)
            {
                LoginView(store: store)
            }

        case .signUp:
            if let store = store.scope(
                state: \.signUp,
                action: \.signUp)
            {
                SignUpView(store: store)
            }

        case .mainTab:
            if let store = store.scope(
                state: \.mainTab,
                action: \.mainTab)
            {
                MainTabView(store: store)
            }
        }
    }
}
