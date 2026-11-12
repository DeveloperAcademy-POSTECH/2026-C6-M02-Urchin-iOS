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
            Color(.brandPrimary)
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

// MARK: - SplashView

/// 앱을 켜면 쓰레기 세 개가 로고의 "o" 안으로 쏙쏙 들어간 뒤 사라져요.
private struct SplashView: View {

    let onFinished: () -> Void

    @State private var isDropping = false

    private static let logoWidth: CGFloat = 182
    /// 로고 가운데에서 첫 글자 뒤 "o"의 가운데까지 거리예요.
    private static let holeOffset = CGSize(width: -31, height: 2)
    private static let dropDuration: TimeInterval = 0.45
    private static let dropGap: TimeInterval = 0.15
    private static let totalDuration: TimeInterval = 1.3

    private static let items: [(image: ImageResource, startX: CGFloat, rotation: Double)] = [
        (.bottleWhiteS, -70, -30),
        (.sodaCanMintS, 10, 25),
        (.plasticBagWhiteS, 70, -15)
    ]

    var body: some View {
        ZStack {
            Color(.brandPrimary)
                .ignoresSafeArea()

            Image(.homeLogo)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(Color(.gray0))
                .frame(width: Self.logoWidth.scaled)
                .keyframeAnimator(initialValue: 1.0, trigger: isDropping) { content, scale in
                    content.scaleEffect(scale)
                } keyframes: { _ in
                    // 쓰레기가 0.45초, 0.6초, 0.75초에 하나씩 들어갈 때마다 로고가 살짝 튀어요
                    LinearKeyframe(1.0, duration: Self.dropDuration)
                    SpringKeyframe(1.06, duration: 0.05)
                    SpringKeyframe(1.0, duration: 0.05)
                    LinearKeyframe(1.0, duration: Self.dropGap - 0.1)
                    SpringKeyframe(1.06, duration: 0.05)
                    SpringKeyframe(1.0, duration: 0.05)
                    LinearKeyframe(1.0, duration: Self.dropGap - 0.1)
                    SpringKeyframe(1.06, duration: 0.05)
                    SpringKeyframe(1.0, duration: 0.05)
                }
                .accessibilityLabel("plobby")

            ForEach(Self.items.indices, id: \.self) { index in
                trash(index)
            }
        }
        .task {
            isDropping = true
            try? await Task.sleep(for: .seconds(Self.totalDuration))
            onFinished()
        }
    }

    private func trash(_ index: Int) -> some View {
        let item = Self.items[index]
        let delay = Double(index) * Self.dropGap

        return Image(item.image)
            .resizable()
            .scaledToFit()
            .frame(width: 28.scaled, height: 28.scaled)
            .rotationEffect(.degrees(isDropping ? 0 : item.rotation))
            .scaleEffect(isDropping ? 0.2 : 1)
            .offset(
                x: (isDropping ? Self.holeOffset.width : item.startX).scaled,
                y: (isDropping ? Self.holeOffset.height : -220).scaled
            )
            .animation(.easeIn(duration: Self.dropDuration).delay(delay), value: isDropping)
            .opacity(isDropping ? 0 : 1)
            .animation(.easeIn(duration: 0.1).delay(delay + Self.dropDuration - 0.05), value: isDropping)
    }
}
