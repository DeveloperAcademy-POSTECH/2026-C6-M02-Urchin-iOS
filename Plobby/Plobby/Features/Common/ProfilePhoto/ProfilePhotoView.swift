//
//  ProfilePhotoView.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import SwiftUI

import ComposableArchitecture

/// 원형 프로필 사진과 "사진 추가" 버튼이에요. 누르면 앱 사진 선택 화면을 띄워요.
/// 알림창은 화면 전체를 덮어야 해서, 쓰는 화면에서 `store.alert`로 띄워요.
struct ProfilePhotoView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<ProfilePhotoFeature>

    // MARK: - Body

    var body: some View {
        Button {
            store.send(.photoTapped)
        } label: {
            VStack(alignment: .center, spacing: 8.scaled) {
                photo

                Text(buttonTitle)
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textBrand))
            }
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading)
        .accessibilityLabel("프로필 \(buttonTitle)")
        .fullScreenCover(item: $store.scope(state: \.photoPicker, action: \.photoPicker)) { store in
            PhotosPickerView(store: store)
        }
    }
}

// MARK: - 사진

extension ProfilePhotoView {

    /// 이미 저장된 사진이 있으면(프로필 수정) "사진 변경", 없으면(회원가입, 사진 없는 프로필) "사진 추가"예요.
    private var buttonTitle: String {
        store.savedImageURL == nil ? "사진 추가" : "사진 변경"
    }

    private var photo: some View {
        Group {
            if let selectedImage = store.selectedImage.flatMap(UIImage.init(data:)) {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
            } else if let savedImageURL = store.savedImageURL {
                AsyncImage(url: savedImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: 96.scaled, height: 96.scaled)
        .clipShape(Circle())
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
    }

    private var placeholder: some View {
        Color(.surfaceSubtle)
            .overlay {
                Image(systemName: "camera.fill")
                    .font(.system(size: 28.scaled, weight: .medium))
                    .foregroundStyle(Color(.buttonPrimaryDisabled))
            }
    }
}
