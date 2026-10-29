//
//  ContentView.swift
//  Plobby
//
//  Created by 더스틴 on 10/22/26.
//

import ComposableArchitecture

import SwiftUI

struct ContentView: View {
    @State private var store = Store(initialState: OnboardingFeature.State()) {
        OnboardingFeature()
    }

    var body: some View {
        LoginTestView(store: store)
    }
}
