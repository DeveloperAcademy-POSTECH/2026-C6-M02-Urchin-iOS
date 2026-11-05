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
    
    // MARK: - Body

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            VStack(spacing: 0) {
                title
                profileImagePicker
                nameSection
                nicknameSection
                
                Spacer()
                
                nextButton
            }
        } destination: { store in
            switch store.case {
            case let .region(store):
                RegionView(store: store)

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
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Subviews

extension SignUpView {
    
    private var title: some View {
        Text("플로비에서 사용할\n프로필을 등록해주세요")
            .font(.system(size: 26, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 21)
            .padding(.horizontal, 20)
            .padding(.bottom, 51)
    }

    private var profileImagePicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            profileImage
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .padding(.bottom, 50)
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .overlay {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.gray)
                }
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이름")
                .font(.system(size: 16, weight: .semibold))

            Text(store.fullName ?? "")
                .font(.system(size: 16, weight: .regular))
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.black)
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.system(size: 16, weight: .semibold))

            HStack(spacing: 8) {
                TextField(
                    "닉네임을 입력해주세요",
                    text: $nicknameText
                )
                .onChange(of: nicknameText) { _, text in
                    let nickname = String(text.prefix(Nickname.maximumLength))
                    
                    nicknameText = nickname
                    store.send(.nicknameChanged(nickname))
                }
                .font(.system(size: 16, weight: .regular))

                Button {
                    store.send(.nicknameCheckButtonTapped)
                } label: {
                    Text("중복확인")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(store.canCheckNickname ? Color.black : Color.gray)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!store.canCheckNickname)
            }
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .frame(height: 50)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3))
            }

            if store.isNicknameFormatInvalid {
                Text("\(Nickname.minimumLength)~\(Nickname.maximumLength)자의 한글, 영문, 숫자만 입력할 수 있어요")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.red)
            } else if let isAvailable = store.isNicknameAvailable {
                Text(isAvailable ? "사용 가능한 닉네임이에요" : "이미 사용 중인 닉네임이에요")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(isAvailable ? .green : .red)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .disabled(!store.canGoNext)
        .padding(.horizontal, 20)
    }
}
