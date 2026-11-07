//
//  ProfileEditView.swift
//  Plobby
//
//  Created by dlsundn on 11/5/26.
//

import PhotosUI
import SwiftUI

import ComposableArchitecture

struct ProfileEditView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ProfileEditFeature>
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var nicknameText = ""
    @FocusState private var isNicknameFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navigationBar
            profileImageSection
            nicknameSection
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        .contentShape(Rectangle())
        .onTapGesture {
            isNicknameFocused = false
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            nicknameText = store.nickname
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }

            store.send(.profileImageLoadingStarted)
            let data = try? await selectedPhoto.loadTransferable(type: Data.self)

            self.selectedPhoto = nil
            store.send(.profileImageSelected(data))
        }
        .task(id: store.selectedImage) {
            previewImage = store.selectedImage.flatMap(UIImage.init(data:))
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Subviews

extension ProfileEditView {

    private var navigationBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                store.send(.backButtonTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 32, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Text("프로필 수정")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.send(.saveButtonTapped)
            } label: {
                Text("저장")
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(store.canSave ? Color(.currentBrandText) : Color(.textDisabled))
                    .frame(height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!store.canSave)
        }
        .frame(height: 56)
    }

    private var profileImageSection: some View {
        VStack(alignment: .center, spacing: 8) {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                preferredItemEncoding: .current
            ) {
                profileImage
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(store.isImageLoading)
            .overlay {
                if store.isImageLoading {
                    ProgressView()
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(store.isImageTooLarge ? Color(.currentError) : .clear, lineWidth: 1)
            }

            if store.isImageTooLarge {
                Text("사진 용량이 2MB를 넘었어요.\n다른 사진을 선택해 주세요.")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.currentError))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 38)
        .padding(.bottom, 36)
    }

    @ViewBuilder
    private var profileImage: some View {
        if store.isImageLoading {
            Color(.gray100)
        } else if store.isImageTooLarge {
            profileImagePlaceholder
        } else if let previewImage {
            profileImageContent(Image(uiImage: previewImage))
        } else {
            AsyncImage(url: store.profile.profileImageURL) { image in
                profileImageContent(image)
            } placeholder: {
                profileImagePlaceholder
            }
        }
    }

    private func profileImageContent(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .overlay {
                photoAddIcon
                    .foregroundStyle(Color(.gray0))
            }
    }

    private var profileImagePlaceholder: some View {
        Color(.gray100)
            .overlay {
                photoAddIcon
                    .foregroundStyle(Color(.gray500))
            }
    }

    private var photoAddIcon: some View {
        Image(systemName: "photo.badge.plus")
            .font(.system(size: 24, weight: .regular))
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("닉네임")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.neutralBlack))

            HStack(alignment: .center, spacing: 10) {
                nicknameField
                nicknameCheckButton
            }

            nicknameMessage
        }
    }

    private var nicknameField: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField(
                "",
                text: $nicknameText,
                prompt: nicknamePlaceholder
            )
            .onChange(of: nicknameText) { _, text in
                let nickname = String(text.prefix(Nickname.maximumLength))

                nicknameText = nickname
                store.send(.nicknameChanged(nickname))
            }
            .plobbyFont(.cardTitle)
            .foregroundStyle(Color(.textPrimary))
            .focused($isNicknameFocused)
            .submitLabel(.done)

            Text("\(store.nickname.count)/\(Nickname.maximumLength)")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textDisabled))
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isNicknameInvalid ? Color(.currentError) : Color(.gray200), lineWidth: 1)
        }
    }

    private var nicknameCheckButton: some View {
        Button {
            store.send(.nicknameCheckButtonTapped)
        } label: {
            Text("중복확인")
                .plobbyFont(store.canCheckNickname ? .labelSelected : .label)
                .foregroundStyle(Color(.textPrimary))
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.gray200), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!store.canCheckNickname)
    }

    @ViewBuilder
    private var nicknameMessage: some View {
        if store.isNicknameFormatInvalid {
            nicknameMessageText(
                "\(Nickname.minimumLength)~\(Nickname.maximumLength)자의 한글, 영문, 숫자만 입력할 수 있어요",
                color: Color(.currentError)
            )
        } else if let isAvailable = store.isNicknameAvailable {
            nicknameMessageText(
                isAvailable ? "사용 가능한 닉네임이에요" : "동일한 닉네임이 있어요",
                color: isAvailable ? Color(.green500) : Color(.currentError)
            )
        }
    }

    private func nicknameMessageText(_ message: String, color: Color) -> some View {
        Text(message)
            .plobbyFont(.helper)
            .foregroundStyle(color)
            .padding(.leading, 8)
    }

    private var nicknamePlaceholder: Text {
        Text("닉네임을 입력해주세요")
            .font(.custom(PlobbyTypography.body.weight.rawValue, fixedSize: PlobbyTypography.body.size))
    }

    private var isNicknameInvalid: Bool {
        store.isNicknameFormatInvalid || store.isNicknameAvailable == false
    }
}
