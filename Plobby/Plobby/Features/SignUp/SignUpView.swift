//
//  SignUpView.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import PhotosUI
import SwiftUI

import ComposableArchitecture

struct SignUpView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SignUpFeature>
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var nicknameText = ""
    @FocusState private var isNicknameFocused: Bool
    
    // MARK: - Body

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            TermsAgreementView(store: store)
        } destination: { pathStore in
            switch pathStore.case {
            case .profile:
                profileForm
                    .plobbyNavigationTitle("회원가입")

            case let .region(store):
                RegionView(store: store)
                    .plobbyNavigationTitle("회원가입")

            case let .complete(store):
                CompleteView(store: store)
            }
        }
        .task(id: selectedPhoto) {
            guard
                let data = try? await selectedPhoto?.loadTransferable(type: Data.self)
            else { return }
            
            selectedPhoto = nil
            store.send(.profileImageSelected(data))
        }
        .task(id: store.profileImage) {
            previewImage = store.profileImage.flatMap(UIImage.init(data:))
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - 프로필 폼

private extension SignUpView {

    var profileForm: some View {
        VStack(spacing: 0) {
            progressBar
            titleSection
            Spacer()
//            profileImagePicker
//            nicknameSection
        }
    }
}

// MARK: - 상단 (진행 바, 제목)

private extension SignUpView {
    
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
    }
}

// MARK: - 프로필 사진

private extension SignUpView {

    var profileImagePicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            profileImage
                .frame(width: 132.scaled, height: 132.scaled)
                .clipShape(RoundedRectangle(cornerRadius: 16.scaled))
                .padding(.bottom, 32.scaled)
        }
    }

    @ViewBuilder
    var profileImage: some View {
        if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
        } else {
            Color(.gray100)
                .overlay {
                    Image(systemName: "photo.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48.scaled, height: 48.scaled)
                        .foregroundStyle(Color(.gray600))
                }
        }
    }
    
}

// MARK: - 닉네임

private extension SignUpView {

    var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("닉네임")
                .plobbyFont(.actionLabel)
                .foregroundStyle(Color(.gray700))

            HStack(spacing: 8.scaled) {
                TextField(
                    "닉네임을 입력해주세요",
                    text: $nicknameText
                )
                .onChange(of: nicknameText) { _, text in
                    let nickname = String(text.prefix(Nickname.maximumLength))
                    
                    nicknameText = nickname
                    store.send(.nicknameChanged(nickname))
                }
                .plobbyFont(.body)
                .foregroundStyle(Color(.textPrimary))

                Button {
                    store.send(.nicknameCheckButtonTapped)
                } label: {
                    Text("중복확인")
                        .plobbyFont(.body)
                        .foregroundStyle(store.canCheckNickname ? Color(.neutralBlack) : Color.gray)
                        .padding(.horizontal, 10.scaled)
                        .frame(height: 34.scaled)
                        .background(
                            store.canCheckNickname ? Color.gray.opacity(0.1) : Color(.gray50),
                            in: RoundedRectangle(cornerRadius: 8.scaled)
                        )
                }
                .disabled(!store.canCheckNickname)
            }
            .padding(.leading, 20.scaled)
            .padding(.trailing, 8.scaled)
            .frame(height: 50.scaled)
            .overlay {
                RoundedRectangle(cornerRadius: 16.scaled)
                    .stroke(Color.gray.opacity(0.3))
            }

            if store.isNicknameFormatInvalid {
                Text("\(Nickname.minimumLength)~\(Nickname.maximumLength)자의 한글, 영문, 숫자만 입력할 수 있어요")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.currentError))
            } else if let isAvailable = store.isNicknameAvailable {
                Text(isAvailable ? "사용 가능한 닉네임이에요" : "이미 사용 중인 닉네임이에요")
                    .plobbyFont(.metadata)
                    .foregroundStyle(isAvailable ? Color.green : Color(.currentError))
            }
        }
        .padding(.horizontal, 20.scaled)
    }
    
    var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .disabled(!store.canGoNext)
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - Preview

#Preview("약관 동의") {
    SignUpView(
        store: Store(initialState: SignUpFeature.State(user: AuthUser(id: UUID(), email: nil))) {
            SignUpFeature()
        }
    )
}

#Preview("프로필 등록") {
    let state = {
        var state = SignUpFeature.State(user: AuthUser(id: UUID(), email: nil))
        state.path.append(.profile(ProfileStepFeature.State()))
        return state
    }()

    SignUpView(
        store: Store(initialState: state) {
            SignUpFeature()
        }
    )
}
