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
        initialState: AppFeature.State.onboarding(
            OnboardingFeature.State()
        )
    ) {
        AppFeature()
    }

    // MARK: - Body
    
    var body: some View {
        switch store.state {
        case .onboarding:
            if let store = store.scope(
                state: \.onboarding,
                action: \.onboarding)
            {
                OnboardingView(store: store)
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
