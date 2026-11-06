//
//  MyView.swift
//  Plobby
//
//  Created by dlsundn on 11/5/26.
//

import SwiftUI

import ComposableArchitecture

struct MyView: View {

    // MARK: - Properties

    let store: StoreOf<MyFeature>
    @State private var savedProfileImage: UIImage?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            profile
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            store.send(.onAppear)
        }
        .task(id: store.savedProfileImage) {
            savedProfileImage = store.savedProfileImage.flatMap(UIImage.init(data:))
        }
    }
}

// MARK: - Subviews

extension MyView {

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("마이")
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.send(.settingsButtonTapped)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.black)
            }
        }
        .frame(height: 56)
    }

    private var profile: some View {
        HStack(alignment: .center, spacing: 16) {
            profileImage

            Text(store.profile?.nickname ?? "")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            profileEditButton
        }
        .padding(.top, 16)
    }

    private var profileImage: some View {
        Group {
            if let savedProfileImage {
                Image(uiImage: savedProfileImage)
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: store.profile?.profileImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(.gray.opacity(0.2))
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }

    private var profileEditButton: some View {
        Button {
            store.send(.profileEditButtonTapped)
        } label: {
            Text("프로필 수정")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay {
                    Capsule()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                }
        }
    }
}
