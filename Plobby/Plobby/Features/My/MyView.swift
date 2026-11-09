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
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if case .member = store.membershipStatus {
                profile
            } else {
                guestLoginPrompt
            }
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

    /// 회원은 함께 보이는 설정 목록이 내비게이션 바를 숨겨서, 직접 뒤로가기 버튼을 둬요
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(.chevronLeft)
                .resizable()
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, -10)
        .accessibilityLabel("뒤로")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 4) {
            backButton

            Text("마이")
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 20))
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            settingsButton
        }
        .frame(height: 56)
    }

    private var settingsButton: some View {
        Button {
            store.send(.settingsButtonTapped)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 44, height: 44, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("설정")
    }

    private var profile: some View {
        HStack(alignment: .center, spacing: 16) {
            profileImage

            Text(store.profile?.nickname ?? "")
                .plobbyFont(.metric)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            profileEditButton
        }
        .padding(.top, 16)
    }

    /// 비회원에게 로그인을 안내하고 바로 Apple 로그인을 할 수 있게 해요
    private var guestLoginPrompt: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("로그인하고 내 활동을 기록해보세요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("로그인 후 내 기록과 프로필을 관리할 수 있어요.")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .padding(.top, 8.scaled)

            Button {
                store.send(.appleLoginButtonTapped)
            } label: {
                AppleLoginLabel()
            }
            .padding(.top, 24.scaled)
        }
        .padding(.top, 16.scaled)
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
                        .fill(Color(.gray100))
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
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 13))
                .foregroundStyle(Color(.textSecondary))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.gray50), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color(.gray500), lineWidth: 1)
                }
        }
    }
}
