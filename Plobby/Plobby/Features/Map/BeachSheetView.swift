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
                .padding(.horizontal, 20.scaled)

            switch store.content {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .empty:
                emptyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .received, .failed:
                VStack(alignment: .leading, spacing: 0) {
                    stats
                        .padding(.horizontal, 20.scaled)
                        .padding(.bottom, 20.scaled)

                    homeButton
                        .padding(.horizontal, 20.scaled)
                        .padding(.bottom, 8.scaled)

                    photos
                }
                .padding(.top, 4.scaled)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(.top, 28.scaled)
        .padding(.bottom, 16.scaled)
        .animation(.easeInOut(duration: 0.2), value: store.content)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        .task(id: store.beach.id) {
            await store.send(.task).finish()
        }
        .fullScreenCover(isPresented: activityPickerBinding) {
            HomeActivityPicker(
                onSelect: { store.send(.activityPicked($0), transaction: Self.noAnimation) },
                onDismiss: { store.send(.activityPickerDismissed, transaction: Self.noAnimation) }
            )
            .presentationBackground(.clear)
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Activity Picker

private extension BeachSheetView {

    var activityPickerBinding: Binding<Bool> {
        Binding(
            get: { store.isActivityPickerPresented },
            set: { if !$0 { store.send(.activityPickerDismissed, transaction: Self.noAnimation) } }
        )
    }

    static var noAnimation: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}

// MARK: - Subviews

private extension BeachSheetView {

    var header: some View {
        HStack(spacing: 16.scaled) {
            Text(store.beach.name)
                .plobbyFont(.headingLarge)
                .foregroundStyle(Color(.textPrimary))
                .lineLimit(1)

            Spacer(minLength: 0)

            if store.isMember, store.isFavorite, store.content != .loading {
                circleIcon(systemName: "star.fill", color: Color(.green500), size: 18, weight: .semibold)
                    .accessibilityLabel("관심 해변")
            }

            circleButton(
                systemName: "xmark",
                color: Color(.textPrimary),
                size: 13,
                weight: .semibold,
                accessibilityLabel: "닫기"
            ) {
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
                store.send(.recordStartTapped, transaction: Self.noAnimation)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15))

                    Text("활동 기록하기")
                        .plobbyFont(.actionLabel)
                }
                .foregroundStyle(Color(.green600))
                .padding(.horizontal, 32.scaled)
                .frame(height: 38.scaled)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.green500), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 8.scaled)
        }
    }

    var homeButton: some View {
        Button {
            store.send(.homeTapped)
        } label: {
            HStack(spacing: 4.scaled) {
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 14.scaled))
                    .frame(width: 20.scaled, height: 20.scaled)

                Text("기록 보기")
                    .plobbyFont(.actionLabel)
            }
            .foregroundStyle(Color(.gray0))
            .padding(.horizontal, 16.scaled)
            .frame(height: 36.scaled)
            .background(Color(.green600), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var photos: some View {
        switch store.content {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: Self.photoSize.scaled)

        case let .received(summary) where !summary.photoURLs.isEmpty:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8.scaled) {
                    ForEach(summary.photoURLs, id: \.self) { url in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color(.gray50)
                        }
                        .frame(width: Self.photoSize.scaled, height: Self.photoSize.scaled)
                        .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                    }
                }
                .padding(.horizontal, 20.scaled)
            }
            .padding(.vertical, 16.scaled)

        case .received, .empty, .failed:
            EmptyView()
        }
    }

    func circleButton(
        systemName: String,
        color: Color,
        size: CGFloat,
        weight: Font.Weight,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            circleIcon(systemName: systemName, color: color, size: size, weight: weight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    func circleIcon(systemName: String, color: Color, size: CGFloat, weight: Font.Weight) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size.scaled, weight: weight))
            .foregroundStyle(color)
            .frame(width: 36.scaled, height: 36.scaled)
            .background(Color(.gray50), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color(.currentWarmBorder), lineWidth: 1)
            }
    }
}
