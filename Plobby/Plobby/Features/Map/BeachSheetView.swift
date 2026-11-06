//
//  BeachSheetView.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct BeachSheetView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<BeachSheetFeature>

    private static let photoSize: CGFloat = 156

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)

            // 기록이 있는지 알기 전에는 이름과 닫기 버튼만 보여줘요.
            switch store.content {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                emptyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .received, .failed:
                VStack(alignment: .leading, spacing: 20) {
                    stats
                        .padding(.horizontal, 20)

                    homeButton
                        .padding(.horizontal, 20)

                    photos
                }
                .padding(.top, 4)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(.top, 28)
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.2), value: store.content)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        // 시트가 열린 채로 다른 핀을 고르면 같은 시트에 해변만 바뀌어요. 해변이 바뀔 때마다 다시 불러와요.
        .task(id: store.beach.id) {
            await store.send(.task).finish()
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Subviews

private extension BeachSheetView {

    var header: some View {
        HStack(spacing: 16) {
            Text(store.beach.name)
                .font(.custom(PretendardWeight.semiBold.rawValue, size: 24))
                .foregroundStyle(Color(.textPrimary))
                .lineLimit(1)

            Spacer(minLength: 0)

            if store.isMember, store.content != .loading {
                circleButton(
                    systemName: store.isFavorite ? "star.fill" : "star",
                    color: store.isFavorite ? Color(.green500) : Color(.textSecondary),
                    accessibilityLabel: store.isFavorite ? "관심 해변 해제" : "관심 해변 등록"
                ) {
                    store.send(.favoriteTapped)
                }
            }

            circleButton(systemName: "xmark", color: Color(.textPrimary), accessibilityLabel: "닫기") {
                store.send(.closeTapped)
            }
        }
    }

    @ViewBuilder
    var stats: some View {
        let text: String = switch store.content {
        case .loading, .empty: ""
        case let .received(summary): "정화활동 \(summary.recordCount)회 • 참여자 \(summary.participantCount)명"
        case .failed: "정보를 불러오지 못했어요"
        }

        Text(text)
            .plobbyFont(.helper)
            .foregroundStyle(Color(.textPrimary))
    }

    /// 기록이 없는 해변. 첫 기록을 남기도록 안내해요.
    var emptyContent: some View {
        VStack(spacing: 8) {
            Text("활동 기록을 등록해보세요")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            Text("해당 바다에 아직 기록이 없어요.\n첫 플로거가 되어주세요.")
                .plobbyFont(.notification)
                .foregroundStyle(Color(.textTertiary))
                .multilineTextAlignment(.center)

            Button {
                store.send(.recordStartTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15))

                    Text("활동 기록하기")
                        .plobbyFont(.actionLabel)
                }
                .foregroundStyle(Color(.green600))
                .padding(.horizontal, 32)
                .frame(height: 38)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.green500), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        // 시트 높이는 그대로 두고 남은 공간의 가운데에 놓여요.
    }

    var homeButton: some View {
        Button {
            store.send(.homeTapped)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 14))

                Text("기록 보기")
                    .plobbyFont(.actionLabel)
            }
            .foregroundStyle(Color(.gray0))
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(Color(.green600), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var photos: some View {
        switch store.content {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: Self.photoSize)

        case let .received(summary) where !summary.photoURLs.isEmpty:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(summary.photoURLs, id: \.self) { url in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color(.gray50)
                        }
                        .frame(width: Self.photoSize, height: Self.photoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 8)

        case .received, .empty, .failed:
            EmptyView()
        }
    }

    func circleButton(
        systemName: String,
        color: Color,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(Color(.gray50), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color(.currentWarmBorder), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
