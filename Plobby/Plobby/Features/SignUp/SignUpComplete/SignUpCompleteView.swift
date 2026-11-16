//
//  SignUpCompleteView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct SignUpCompleteView: View {

    // MARK: - Properties

    let store: StoreOf<SignUpCompleteFeature>
    @State private var iconCenter: CGPoint?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()

            completeMessage

            Spacer()

            startButton
        }
        .padding(.horizontal, 20.scaled)
        .coordinateSpace(.named(Self.coordinateSpaceName))
        .overlay {
            ConfettiBurstView(origin: iconCenter)
        }
        .navigationBarBackButtonHidden()
    }
}

// MARK: - Constants

private extension SignUpCompleteView {

    nonisolated static let coordinateSpaceName = "signUpComplete"
}

// MARK: - 완료 안내

private extension SignUpCompleteView {

    var completeMessage: some View {
        VStack(spacing: 16.scaled) {
            checkmarkIcon

            Text("plobby에 오신걸 환영해요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("플로깅과 플로빙을 기록하고 함께 목표를 채워봐요")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .multilineTextAlignment(.center)
    }

    var checkmarkIcon: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 22.scaled, weight: .medium))
            .foregroundStyle(Color(.textBrand))
            .frame(width: 64.scaled, height: 64.scaled)
            .background(Color(.brandPrimarySubtle), in: Circle())
            .onGeometryChange(for: CGPoint.self) { proxy in
                let frame = proxy.frame(in: .named(Self.coordinateSpaceName))
                return CGPoint(x: frame.midX, y: frame.midY)
            } action: { center in
                iconCenter = center
            }
            .accessibilityHidden(true)
    }
}

// MARK: - 시작하기

private extension SignUpCompleteView {

    var startButton: some View {
        PlobbyButton(text: "시작하기") {
            store.send(.completeButtonTapped)
        }
    }
}
