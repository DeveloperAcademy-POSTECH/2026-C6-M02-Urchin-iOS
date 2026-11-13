//
//  BlockedUsersView.swift
//  Plobby
//
//  Created by 더스틴 on 11/7/26.
//

import SwiftUI

import ComposableArchitecture

struct BlockedUsersView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<BlockedUsersFeature>

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlobbyNavigationBar(title: "차단한 사용자", style: .leading) {
                store.send(.backButtonTapped)
            }

            content
        }
        .background(Color(.gray0))
        .toolbar(.hidden, for: .navigationBar)
        .plobbyToast(store.toast.toastType)
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - Subviews

extension BlockedUsersView {

    @ViewBuilder
    private var content: some View {
        switch store.blockedUsers {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            message("차단한 사용자가 없어요")

        case .failed:
            message("목록을 불러오지 못했어요")

        case let .loaded(users):
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(users) { user in
                        row(user)
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }

    private func row(_ user: BlockedUser) -> some View {
        HStack(spacing: 16) {
            profileImage(user.profileImageURL)

            Text(user.nickname)
                .plobbyFont(.actionLabel)
                .foregroundStyle(Color(.textPrimary))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            blockToggleButton(user)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func profileImage(_ url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.gray300))
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }

    private func blockToggleButton(_ user: BlockedUser) -> some View {
        let isBlocked = store.state.isBlocked(user.id)

        return Button {
            store.send(.blockToggleTapped(user.id))
        } label: {
            Text(isBlocked ? "차단 해제" : "차단하기")
                .plobbyFont(.label)
                .foregroundStyle(Color(.currentError))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.gray50), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color(.currentError), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(store.updatingUserID == user.id)
        .accessibilityLabel(isBlocked ? "\(user.nickname) 차단 해제" : "\(user.nickname) 다시 차단")
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textTertiary))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
