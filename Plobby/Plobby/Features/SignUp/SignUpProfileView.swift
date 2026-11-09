//
//  SignUpProfileView.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SwiftUI

import ComposableArchitecture

struct SignUpProfileView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SignUpFeature>
    @State private var nicknameText = ""
    @FocusState private var isNicknameFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            titleSection
            profilePhotoSection
            nicknameSection
            
            Spacer()
            
            nextButton
        }
    }
}

// MARK: - 상단 (진행 바, 제목)

private extension SignUpProfileView {
    
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

// MARK: - 프로필 사진

private extension SignUpProfileView {
    
    var profilePhotoSection: some View {
        Button {
            store.send(.profilePhotoTapped)
        } label: {
            VStack(spacing: 8.scaled) {
                profilePhoto
                addPhotoLabel
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("프로필 사진 추가")
        .padding(.bottom, 32.scaled)
    }

    var profilePhoto: some View {
        Group {
            if let image = store.profileImage.flatMap(UIImage.init(data:)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.surfaceSubtle)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28.scaled, weight: .medium))
                            .foregroundStyle(Color(.buttonPrimaryDisabled))
                    }
            }
        }
        .frame(width: 96.scaled, height: 96.scaled)
        .clipShape(Circle())
    }

    var addPhotoLabel: some View {
        Text("사진 추가")
            .plobbyFont(.labelSelected)
            .foregroundStyle(Color(.textBrand))
    }
}

// MARK: - 닉네임

private extension SignUpProfileView {

    var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            nicknameTextLabel
                .padding(.bottom, 12.scaled)
            nicknameTextField
            nicknameGuideText
        }
        .padding(.horizontal, 20.scaled)
    }
    
    var nicknameTextLabel: some View {
        Text("닉네임")
            .plobbyFont(.cardTitle)
            .foregroundStyle(Color(.textPrimary))
    }
    
    var nicknameTextField: some View {
        HStack(spacing: 8.scaled) {
            TextField(
                "",
                text: $nicknameText,
                prompt: Text("닉네임 입력")
                    .foregroundStyle(Color(.textSecondary))
            )
            .onChange(of: nicknameText) { _, text in
                let nickname = String(text.prefix(Nickname.maximumLength))

                nicknameText = nickname
                store.send(.nicknameChanged(nickname))
            }
            .focused($isNicknameFocused)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)

            nicknameCheckButton
        }
        .padding(.horizontal, 12.scaled)
        .frame(height: 51.scaled)
        .background(Color(.backgroundDefault), in: RoundedRectangle(cornerRadius: 8.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 8.scaled)
                .strokeBorder(store.hasNicknameError ? Color(.currentError) : Color(.borderDefault), lineWidth: 1)
        }
    }

    var nicknameCheckButton: some View {
        Button {
            store.send(.nicknameCheckButtonTapped)
        } label: {
            Text("중복 확인")
                .plobbyFont(.label)
                .foregroundStyle(store.canCheckNickname ? Color(.textBrand) : Color(.textDisabled))
                .padding(.horizontal, 18.scaled)
                .frame(height: 40.scaled)
                .background(
                    store.canCheckNickname ? Color(.brandPrimarySubtle) : Color(.surfaceSubtle),
                    in: RoundedRectangle(cornerRadius: 8.scaled)
                )
        }
        .buttonStyle(.plain)
        .disabled(!store.canCheckNickname)
    }
    
    @ViewBuilder
    var nicknameGuideText: some View {
        if store.isNicknameFormatInvalid {
            Text("\(Nickname.minimumLength)~\(Nickname.maximumLength)자의 한글, 영문, 숫자만 입력할 수 있어요")
                .plobbyFont(.helper)
                .foregroundStyle(Color(.currentError))
        } else if let isAvailable = store.isNicknameAvailable {
            Text(isAvailable ? "사용 가능한 닉네임이에요" : "이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해주세요.")
                .plobbyFont(.helper)
                .foregroundStyle(isAvailable ? Color(.textBrand) : Color(.currentError))
        }
    }
}

// MARK: - 다음

private extension SignUpProfileView {

    var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .disabled(!store.canGoNext)
        .padding(.horizontal, 20.scaled)
    }
}
