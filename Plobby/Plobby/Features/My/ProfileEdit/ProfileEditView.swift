//
//  ProfileEditView.swift
//  Plobby
//
//  Created by dlsundn on 11/5/26.
//

import SwiftUI

import ComposableArchitecture

struct ProfileEditView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ProfileEditFeature>
    @FocusState private var isNicknameFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlobbyNavigationBar(title: "프로필 수정", style: .leading, isTrailingEnabled: store.canSave) {
                store.send(.backButtonTapped)
            } trailingAction: {
                store.send(.saveButtonTapped)
            } trailingLabel: {
                Text("저장")
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(store.canSave ? Color(.currentBrandText) : Color(.textDisabled))
            }

            ProfilePhotoView(store: store.scope(state: \.profilePhoto, action: \.profilePhoto))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40.scaled)

            NicknameCheckView(
                store: store.scope(state: \.nicknameCheck, action: \.nicknameCheck),
                isFocused: $isNicknameFocused
            )
            .padding(.top, 36.scaled)
            .padding(.horizontal, 20.scaled)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        .contentShape(Rectangle())
        .onTapGesture {
            isNicknameFocused = false
        }
        .toolbar(.hidden, for: .navigationBar)
        .plobbyAlert($store.scope(state: \.profilePhoto.alert, action: \.profilePhoto.alert))
        .plobbyAlert($store.scope(state: \.nicknameCheck.alert, action: \.nicknameCheck.alert))
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}
