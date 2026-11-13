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

    @Bindable var store: StoreOf<MyFeature>
    @State private var savedProfileImage: UIImage?
    @State private var menuRecord: RecordSummary?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.isMember {
                PlobbyNavigationBar(title: "마이") {
                    dismiss()
                } trailingAction: {
                    store.send(.settingsButtonTapped)
                } trailingLabel: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 24.scaled, weight: .regular))
                        .foregroundStyle(Color(.textPrimary))
                        .accessibilityLabel("설정")
                }
            } else {
                PlobbyNavigationBar(title: "마이") {
                    dismiss()
                }
            }

            content
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .recordMoreMenu(record: $menuRecord, isMine: { _ in true }) { record, menu in
            store.send(.recordMenuSelected(record, menu))
        }
        .recordMenu(store: store.scope(state: \.recordMenu, action: \.recordMenu.presented))
        .plobbyToast(store.toast.toastType) {
            store.send(.favoriteBeachUndoButtonTapped, animation: Self.favoriteBeachAnimation)
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.isMember) {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.favoriteBeachAdd, action: \.favoriteBeachAdd)) { store in
            FavoriteBeachAddView(store: store)
                .presentationDetents([.height(FavoriteBeachAddView.sheetHeight)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.gray0))
        }
        .task(id: store.savedProfileImage) {
            savedProfileImage = store.savedProfileImage.flatMap(UIImage.init(data:))
        }
    }
}

// MARK: - Content

extension MyView {

    private var content: some View {
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
                    onRecordTapped: { store.send(.recordTapped($0)) },
                    onMoreTapped: { menuRecord = $0 },
                    menuRecordID: menuRecord?.id
                ) {
                    if store.isMember {
                        RecordListEmptyMessage()
                    } else {
                        guestRecordPrompt
                    }
                }
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

            Text(store.isMember ? store.profile?.nickname ?? "" : "로그인이 필요해요")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            if store.isMember {
                profileEditButton
            }
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
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(Color(.gray600))
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
            activitySummaryCard(title: "활동 기록", value: memberValue("\(store.records.count)개"))
            activitySummaryCard(title: "수거 개수", value: memberValue("\(store.collectedTrashCount)개"))
            activitySummaryCard(
                title: "수거 무게",
                value: memberValue("\(store.collectedWeightKg.formatted(.number.precision(.fractionLength(0...1))))kg")
            )
        }
    }

    private func memberValue(_ value: String) -> String {
        store.isMember ? value : "-"
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

    private var guestRecordPrompt: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("로그인 후 활동을 기록해보세요")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            Text("새 기록으로\n지도에 활동 흔적을 남겨보아요")
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textTertiary))
                .multilineTextAlignment(.center)
                .padding(.top, 8.scaled)

            Button {
                store.send(.recordStartButtonTapped)
            } label: {
                HStack(alignment: .center, spacing: 6.scaled) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14.scaled, weight: .regular))

                    Text("활동 기록하기")
                        .plobbyFont(.labelSelected)
                }
                .foregroundStyle(Color(.green600))
                .padding(.horizontal, 20.scaled)
                .frame(height: 36.scaled)
                .overlay {
                    Capsule()
                        .stroke(Color(.green500), lineWidth: 1)
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 16.scaled)
        }
    }
}

// MARK: - 관심 해변

extension MyView {

    /// 관심 해변을 해제하거나 되돌릴 때 카드가 천천히 빠지고 돌아오게 해요.
    private static let favoriteBeachAnimation: Animation = .easeInOut(duration: 0.5)

    private var favoriteBeachSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            HStack(alignment: .center, spacing: 0) {
                sectionTitle("관심 해변")

                favoriteBeachAddButton
            }
            .padding(.horizontal, 20.scaled)

            if !store.isMember {
                EmptyView()
            } else if store.favoriteBeaches.isEmpty {
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
                    .animation(Self.favoriteBeachAnimation, value: store.favoriteBeaches)
                }
            }
        }
    }

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
