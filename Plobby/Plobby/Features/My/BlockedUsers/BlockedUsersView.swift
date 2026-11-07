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
            navigationBar

            content
        }
        .background(Color(.gray0))
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            toast
        }
        .animation(.easeInOut(duration: 0.2), value: store.toast.toastMessage)
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - Subviews

extension BlockedUsersView {

    private var navigationBar: some View {
        HStack(spacing: 8) {
            Button {
                store.send(.backButtonTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 24, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            Text("차단한 사용자")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }

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

    /// 차단 중이면 "차단 중", 이 화면에서 해제했으면 "차단하기"를 보여줘요.
    private func blockToggleButton(_ user: BlockedUser) -> some View {
        let isBlocked = store.state.isBlocked(user.id)

        return Button {
            store.send(.blockToggleTapped(user.id))
        } label: {
            Text(isBlocked ? "차단 중" : "차단하기")
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

    @ViewBuilder
    private var toast: some View {
        if let message = store.toast.toastMessage {
            Text(message)
                .plobbyFont(.body)
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(.gray800), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity)
                .accessibilityAddTraits(.isStaticText)
        }
    }
}
