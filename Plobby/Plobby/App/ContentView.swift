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
    
    @State private var store = Store(initialState: OnboardingFeature.State()) {
        OnboardingFeature()
    }

    // MARK: - Body
    
    var body: some View {
        OnboardingView(store: store)
    }
}
