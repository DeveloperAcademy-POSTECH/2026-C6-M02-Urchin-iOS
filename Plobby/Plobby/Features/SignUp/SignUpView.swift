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
            if store.isAgreementCompleted {
                profileForm
            } else {
                TermsAgreementView(store: store)
            }
        } destination: { store in
            switch store.case {
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

// MARK: - Subviews

extension SignUpView {

    /// 키보드가 올라오면 내용은 스크롤로 밀어 올리고, 다음 버튼은 키보드 바로 위에 붙어요
    private var profileForm: some View {
        ScrollView {
            VStack(spacing: 0) {
                title
                profileImagePicker
                // FIXME: Apple이 이름을 첫 로그인에만 줘서 빈 칸으로 보이는 경우가 있어 숨겨둠. 이름 입력 방식 정해지면 다시 표시
                // nameSection
                nicknameSection
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        // 빈 곳을 누르면 키보드를 내려요
        .contentShape(Rectangle())
        .onTapGesture {
            isNicknameFocused = false
        }
        .safeAreaInset(edge: .bottom) {
            nextButton
                .padding(.bottom, 8.scaled)
        }
    }
    
    private var title: some View {
        Text("프로필을 등록해주세요")
            .plobbyFont(.headingLarge)
            .foregroundStyle(Color(.textPrimary))
            .frame(maxWidth: .infinity, alignment: .leading)
            // 내비게이션 바가 없는 화면이라 시안 여백 24에 내비게이션 바 높이(44)를 더해요
            .padding(.top, (24 + Self.navigationBarHeight).scaled)
            .padding(.horizontal, 20.scaled)
            .padding(.bottom, 68.scaled)
    }

    private var profileImagePicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            profileImage
                .frame(width: 132.scaled, height: 132.scaled)
                .clipShape(RoundedRectangle(cornerRadius: 16.scaled))
                .padding(.bottom, 32.scaled)
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFill()
        } else {
            Self.profilePlaceholderColor
                .overlay {
                    Image(systemName: "photo.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48.scaled, height: 48.scaled)
                        .foregroundStyle(Color(.gray600))
                }
        }
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("이름")
                .plobbyFont(.actionLabel)
                .foregroundStyle(Color(.gray700))

            Text(store.fullName ?? "")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textPrimary))
                .focused($isNicknameFocused)
                .submitLabel(.done)
                .padding(.horizontal, 20.scaled)
                .frame(maxWidth: .infinity, minHeight: 50.scaled, alignment: .leading)
                .overlay {
                    RoundedRectangle(cornerRadius: 16.scaled)
                        .stroke(.black)
                }
        }
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 4.scaled)
    }

    private var nicknameSection: some View {
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
    
    private var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .disabled(!store.canGoNext)
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - Constants

extension SignUpView {

    private static let navigationBarHeight: CGFloat = 44

    // TODO: 컬러셋 확정 후 교체 (#F2F4F7)
    private static let profilePlaceholderColor = Color(red: 0xF2 / 255, green: 0xF4 / 255, blue: 0xF7 / 255)
}
