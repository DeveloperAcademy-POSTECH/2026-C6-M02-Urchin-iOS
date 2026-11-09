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
                .padding(.horizontal, 20.scaled)

            if case .member = store.membershipStatus {
                memberContent
            } else {
                guestLoginPrompt
                    .padding(.horizontal, 20.scaled)
            }
        }
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
                .frame(width: 24.scaled, height: 24.scaled)
                .frame(width: 44.scaled, height: 44.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, -10.scaled)
        .accessibilityLabel("뒤로")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 4.scaled) {
            backButton

            Text("마이")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            settingsButton
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

    private var memberContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40.scaled) {
                profile
                    .padding(.horizontal, 20.scaled)

                favoriteBeachSection

                recordSection
                    .padding(.horizontal, 20.scaled)
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

// MARK: - 관심 해변

extension MyView {

    /// 누르는 영역은 44pt로 넓히되, 제목 줄 높이는 디자인대로 유지해요.
    private static let manageButtonTouchInset: CGFloat = 11

    private var favoriteBeachSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            HStack(alignment: .center, spacing: 0) {
                sectionTitle("관심 해변")

                Button {
                    store.send(.favoriteBeachManageButtonTapped)
                } label: {
                    Text("관리")
                        .plobbyFont(.label)
                        .foregroundStyle(Color(.textSecondary))
                        .padding(.vertical, Self.manageButtonTouchInset.scaled)
                        .contentShape(Rectangle())
                        .padding(.vertical, -Self.manageButtonTouchInset.scaled)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20.scaled)

            if store.favoriteBeaches.isEmpty {
                Text("관리에서 자주 가는 해변을 추가해 보세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textTertiary))
                    .padding(.horizontal, 20.scaled)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 8.scaled) {
                        ForEach(store.favoriteBeaches) { beach in
                            Button {
                                store.send(.favoriteBeachTapped(beach))
                            } label: {
                                favoriteBeachCard(beach)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20.scaled)
                }
            }
        }
    }

    private func favoriteBeachCard(_ beach: Beach) -> some View {
        HStack(alignment: .center, spacing: 12.scaled) {
            VStack(alignment: .leading, spacing: 2.scaled) {
                Text(beach.name)
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textPrimary))

                Text(beach.address)
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 14.scaled, weight: .medium))
                .foregroundStyle(Color(.textTertiary))
        }
        .padding(.horizontal, 16.scaled)
        .padding(.vertical, 12.scaled)
        .frame(width: 172.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
    }
}

// MARK: - 활동 기록

extension MyView {

    private static let recentDayCount = 7

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("활동 기록")

            recordFilterChips
                .padding(.top, 16.scaled)

            Text("\(store.filteredRecords.count)개")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.gray600))
                .padding(.top, 16.scaled)

            if store.filteredRecords.isEmpty {
                Text("아직 활동 기록이 없어요")
                    .plobbyFont(.label)
                    .foregroundStyle(Color(.textTertiary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40.scaled)
            } else {
                recordList
            }
        }
    }

    private var recordFilterChips: some View {
        HStack(alignment: .center, spacing: 8.scaled) {
            ForEach(RecordFilter.allCases, id: \.self) { filter in
                let isSelected = store.recordFilter == filter

                Button {
                    store.send(.recordFilterChanged(filter))
                } label: {
                    Text(filter.title)
                        .plobbyFont(.labelSelected)
                        .foregroundStyle(isSelected ? Color(.gray0) : Color(.textPrimary))
                        .padding(.horizontal, 16.scaled)
                        .frame(height: 36.scaled)
                        .background(isSelected ? Color(.gray800) : Color(.gray50), in: Capsule())
                        .overlay {
                            if !isSelected {
                                Capsule()
                                    .stroke(Color(.currentWarmBorder), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recordList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.filteredRecords) { record in
                Button {
                    store.send(.recordTapped(record.id))
                } label: {
                    recordRow(record)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if record.id != store.filteredRecords.last?.id {
                    Divider()
                }
            }
        }
    }

    private func recordRow(_ record: RecordSummary) -> some View {
        HStack(alignment: .top, spacing: 32.scaled) {
            VStack(alignment: .leading, spacing: 0) {
                Text(record.title)
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(Color(.textPrimary))
                    .lineLimit(1)

                recordDate(record.createdAt)
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.gray600))
                    .padding(.top, 6.scaled)

                if record.likeCount > 0 {
                    HStack(alignment: .center, spacing: 2.scaled) {
                        Image(systemName: "heart")
                        Text("\(record.likeCount)")
                    }
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.gray600))
                    .frame(maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            AsyncImage(url: record.coverPhotoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.gray50)
            }
            .frame(width: 108.scaled, height: 108.scaled)
            .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
        }
        .frame(height: 108.scaled)
        .padding(.vertical, 16.scaled)
    }

    /// 최근 7일 안의 기록은 "1일 전"처럼, 그보다 오래된 기록은 "2026.10.08"처럼 보여줘요.
    private func recordDate(_ date: Date) -> Text {
        let recentLimit = Calendar.current.date(byAdding: .day, value: -Self.recentDayCount, to: .now) ?? .now
        let dateFormat = Date.VerbatimFormatStyle(
            format: "\(year: .defaultDigits).\(month: .twoDigits).\(day: .twoDigits)",
            timeZone: .current,
            calendar: .current
        )

        return date > recentLimit
            ? Text(date, format: .relative(presentation: .numeric))
            : Text(date, format: dateFormat)
    }
}

// TODO: 구현 끝나면 삭제

#Preview {
    NavigationStack {
        MyView(store: Store(initialState: .preview) {
            EmptyReducer()
        })
    }
}

private extension MyFeature.State {

    static var preview: Self {
        @Shared(.membershipStatus) var membershipStatus
        $membershipStatus.withLock { $0 = .member(AuthUser(id: UUID(), email: nil, fullName: nil)) }

        var state = Self()
        state.profile = Profile(userID: UUID(), nickname: "포항물회", profileImageKey: nil, profileImageURL: nil)
        state.$favoriteBeaches.withLock {
            $0 = [
                Beach(id: UUID(), region: .east, name: "송도 해수욕장", address: "경북 포항시 남구", latitude: 0, longitude: 0),
                Beach(id: UUID(), region: .east, name: "안목 해변", address: "강원 강릉시", latitude: 0, longitude: 0),
                Beach(id: UUID(), region: .south, name: "부산 송도 해수욕장", address: "부산 서구", latitude: 0, longitude: 0)
            ]
        }
        state.records = [
            .preview(title: "영일대 해수욕장 플로깅", recordType: .plogging, daysAgo: 1, likeCount: 12),
            .preview(title: "송도 해수욕장 플로깅", recordType: .plogging, daysAgo: 32, likeCount: 12),
            .preview(title: "칠포 해수욕장 플로빙", recordType: .plobbing, daysAgo: 18, likeCount: 0)
        ]
        return state
    }
}

private extension RecordSummary {

    static func preview(title: String, recordType: RecordType, daysAgo: Int, likeCount: Int) -> Self {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now

        return RecordSummary(
            id: UUID(),
            userID: UUID(),
            beachID: UUID(),
            beachName: "송도 해수욕장",
            recordType: recordType,
            title: title,
            startedAt: date,
            endedAt: date,
            weightKg: nil,
            depthM: nil,
            trashCount: 5,
            nickname: "포항물회",
            profileImageURL: nil,
            coverPhotoURL: nil,
            trashNames: nil,
            likeCount: likeCount,
            likedByMe: false,
            createdAt: date
        )
    }
}
