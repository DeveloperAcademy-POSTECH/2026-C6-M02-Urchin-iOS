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
            navigationBar
                .padding(.horizontal, 20.scaled)

            if case .member = store.membershipStatus {
                memberContent
            } else {
                guestLoginPrompt
                    .padding(.horizontal, 20.scaled)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .plobbyToast(
            store.toast.toastMessage,
            actionTitle: store.removedFavoriteBeach == nil ? nil : "되돌리기",
            action: { store.send(.favoriteBeachUndoButtonTapped, animation: Self.favoriteBeachAnimation) }
        )
        .onAppear {
            store.send(.onAppear)
        }
        .task(id: store.savedProfileImage) {
            savedProfileImage = store.savedProfileImage.flatMap(UIImage.init(data:))
        }
    }
}

// MARK: - Navigation Bar

extension MyView {

    private var navigationBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17.scaled, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 32.scaled, height: 44.scaled, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")
            .frame(maxWidth: .infinity, alignment: .leading)

            settingsButton
        }
        .overlay {
            Text("마이")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
        }
        .frame(height: 56.scaled)
    }

    private var settingsButton: some View {
        Button {
            store.send(.settingsButtonTapped)
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 24.scaled, weight: .regular))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 44.scaled, height: 44.scaled, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("설정")
    }
}

// MARK: - Content

extension MyView {

    private var memberContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16.scaled) {
                    profile

                    activitySummary
                }
                .padding(.horizontal, 20.scaled)
                .padding(.bottom, 16.scaled)

                favoriteBeachSection
                    .padding(.top, 16.scaled)
                    .padding(.bottom, 24.scaled)

                RecordListSection(
                    records: store.filteredRecords,
                    selectedFilter: store.recordFilter,
                    onFilterChanged: { store.send(.recordFilterChanged($0)) },
                    onRecordTapped: { store.send(.recordTapped($0)) }
                )
                .padding(.horizontal, 20.scaled)
                .padding(.top, 16.scaled)
            }
            .padding(.bottom, 24.scaled)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .plobbyFont(.cardTitle)
            .foregroundStyle(Color(.textPrimary))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 프로필

extension MyView {

    private var profile: some View {
        HStack(alignment: .center, spacing: 16.scaled) {
            profileImage

            Text(store.profile?.nickname ?? "")
                .plobbyFont(.metric)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            profileEditButton
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
        .frame(width: 48.scaled, height: 48.scaled)
        .clipShape(Circle())
    }

    private var profileEditButton: some View {
        Button {
            store.send(.profileEditButtonTapped)
        } label: {
            Text("프로필 수정")
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 13.scaled))
                .foregroundStyle(Color(.textSecondary))
                .padding(.horizontal, 12.scaled)
                .padding(.vertical, 8.scaled)
                .background(Color(.gray50), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color(.gray500), lineWidth: 1)
                }
        }
    }
}

// MARK: - 활동 요약

extension MyView {

    private var activitySummary: some View {
        HStack(alignment: .center, spacing: 8.scaled) {
            activitySummaryCard(title: "활동 기록", value: "\(store.records.count)개")
            activitySummaryCard(title: "수거 개수", value: "\(store.collectedTrashCount)개")
            activitySummaryCard(
                title: "수거 무게",
                value: "\(store.collectedWeightKg.formatted(.number.precision(.fractionLength(0...1))))kg"
            )
        }
    }

    private func activitySummaryCard(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4.scaled) {
            Text(title)
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.textTertiary))

            Text(value)
                .plobbyFont(.metric)
                .foregroundStyle(Color(.currentBrandText))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
    }
}

// MARK: - 비회원

extension MyView {

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
}

// MARK: - 관심 해변

extension MyView {

    /// 관심 해변을 해제하거나 되돌릴 때 카드가 천천히 빠지고 돌아오게 해요.
    private static let favoriteBeachAnimation: Animation = .easeInOut(duration: 0.3)

    private var favoriteBeachSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            HStack(alignment: .center, spacing: 0) {
                sectionTitle("관심 해변")

                favoriteBeachAddButton
            }
            .padding(.horizontal, 20.scaled)

            if store.favoriteBeaches.isEmpty {
                Text("+를 눌러 자주 가는 해변을 추가해 보세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textTertiary))
                    .padding(.horizontal, 20.scaled)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 12.scaled) {
                        ForEach(store.favoriteBeaches) { beach in
                            Button {
                                store.send(.favoriteBeachTapped(beach))
                            } label: {
                                favoriteBeachCard(beach)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .padding(.horizontal, 20.scaled)
                }
            }
        }
    }

    /// 관심 해변이 최대 개수만큼 있으면 더 추가할 수 없어서 흐리게 보여줘요.
    private var favoriteBeachAddButton: some View {
        Button {
            store.send(.favoriteBeachAddButtonTapped)
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: 20.scaled, weight: .regular))
                .foregroundStyle(store.isFavoriteBeachLimitReached ? Color(.textTertiary) : Color(.textPrimary))
                .frame(width: 24.scaled, height: 24.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(store.isFavoriteBeachLimitReached)
        .accessibilityLabel("관심 해변 추가")
    }

    private func favoriteBeachCard(_ beach: Beach) -> some View {
        HStack(alignment: .center, spacing: 12.scaled) {
            VStack(alignment: .leading, spacing: 2.scaled) {
                Text(beach.name)
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(Color(.textPrimary))

                Text(beach.address)
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.send(.favoriteBeachUnfavoriteButtonTapped(beach), animation: Self.favoriteBeachAnimation)
            } label: {
                Image(systemName: "star.fill")
                    .font(.system(size: 12.scaled, weight: .regular))
                    .foregroundStyle(Color(.green500))
                    .frame(width: 15.scaled, height: 14.scaled)
                    .frame(width: 32.scaled, height: 32.scaled)
                    .background(Color(.gray50), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("관심 해변 해제")
        }
        .padding(.horizontal, 16.scaled)
        .padding(.vertical, 14.scaled)
        .frame(width: 210.scaled)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 16.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 16.scaled)
                .stroke(Color(.currentWarmBorder), lineWidth: 1)
        }
    }
}
