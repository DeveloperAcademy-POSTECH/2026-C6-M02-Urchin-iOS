//
//  ProfileSetupView.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SwiftUI

import ComposableArchitecture

struct ProfileSetupView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ProfileSetupFeature>
    @FocusState private var isNicknameFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PlobbyNavigationBar(title: "회원가입") {
                store.send(.backButtonTapped)
            }

            progressBar
            titleSection

            ProfilePhotoView(store: store.scope(state: \.profilePhoto, action: \.profilePhoto))
                .padding(.bottom, 32.scaled)

            NicknameCheckView(
                store: store.scope(state: \.nicknameCheck, action: \.nicknameCheck),
                isFocused: $isNicknameFocused,
                showsAvailableMessage: true
            )
            .padding(.horizontal, 20.scaled)
            
            Spacer()
            
            nextButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .contentShape(Rectangle())
        .onTapGesture {
            isNicknameFocused = false
        }
        .plobbyAlert(store: store, state: \.profilePhoto.alert, action: \.profilePhoto.alert)
        .plobbyAlert(store: store, state: \.nicknameCheck.alert, action: \.nicknameCheck.alert)
    }
}

// MARK: - 상단 (진행 바, 제목)

private extension ProfileSetupView {
    
    var progressBar: some View {
        SignUpProgressBar(currentStep: 1, totalSteps: 2)
            .padding(.top, 23.scaled)
            .padding(.bottom, 31.scaled)
            .padding(.horizontal, 20.scaled)
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("프로필을 등록해주세요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("사진과 닉네임을 추가해 주세요")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 24.scaled)
    }
}

// MARK: - 다음

private extension ProfileSetupView {

    var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .disabled(!store.canGoNext)
        .padding(.horizontal, 20.scaled)
    }
}
