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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()

            completeMessage

            Spacer()

            startButton
        }
        .padding(.horizontal, 20.scaled)
        .navigationBarBackButtonHidden()
    }
}

// MARK: - 완료 안내

private extension SignUpCompleteView {

    var completeMessage: some View {
        VStack(spacing: 16.scaled) {
            checkmarkIcon

            Text("회원가입이 완료됐어요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("플로깅과 플로빙 활동을 기록해 보세요")
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

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpCompleteView(
            store: Store(initialState: SignUpCompleteFeature.State()) {
                SignUpCompleteFeature()
            }
        )
    }
}
