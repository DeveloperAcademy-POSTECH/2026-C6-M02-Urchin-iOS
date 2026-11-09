//
//  RecordDetailView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordDetailView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<RecordDetailFeature>

    private static let photoHeight: CGFloat = 224.scaled

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            switch store.loadState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(record):
                content(record)

            case .failed:
                failedView
            }
        }
        .background(Color(.gray0))
        .task {
            await store.send(.task).finish()
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
        .fullScreenCover(item: $store.scope(state: \.editForm, action: \.editForm)) { store in
            RecordFormView(store: store)
        }
        .navigationDestination(item: $store.scope(state: \.userHome, action: \.userHome)) { store in
            UserHomeView(store: store)
                .toolbar(.hidden, for: .tabBar)
        }
    }
}

// MARK: - Navigation Bar

private extension RecordDetailView {

    var navigationBar: some View {
        HStack(spacing: 0) {
            navigationButton(systemName: "chevron.left", accessibilityLabel: "뒤로") {
                store.send(.backTapped)
            }

            Spacer()

            moreMenu
                .opacity(store.record == nil ? 0 : 1)
                .disabled(store.record == nil)
        }
        .overlay {
            Text("기록 상세")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
        }
        .padding(.horizontal, 20.scaled)
        .frame(height: 56.scaled)
    }

    /// 버튼 바로 아래에 시스템 팝업 메뉴로 떠요.
    var moreMenu: some View {
        Menu {
            if store.record?.isMine == true {
                Button("수정하기") {
                    store.send(.moreMenuSelected(.editTapped))
                }
                Button("삭제하기", role: .destructive) {
                    store.send(.moreMenuSelected(.deleteTapped))
                }
            } else {
                Button("신고하기") {
                    store.send(.moreMenuSelected(.reportTapped))
                }
                Button("차단하기", role: .destructive) {
                    store.send(.moreMenuSelected(.blockTapped))
                }
            }
        } label: {
            navigationIcon(systemName: "ellipsis")
        }
        .accessibilityLabel("기록 더보기")
    }

    func navigationIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 17.scaled, weight: .medium))
            .foregroundStyle(Color(.textPrimary))
            .frame(width: 44.scaled, height: 44.scaled)
            .contentShape(Rectangle())
    }

    func navigationButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            navigationIcon(systemName: systemName)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 내용

private extension RecordDetailView {

    func content(_ record: RecordDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40.scaled) {
                header(record)
                summarySection(record)
                trashSection
                memoSection(record)
            }
            .padding(.horizontal, 20.scaled)
            .padding(.top, 24.scaled)
            .padding(.bottom, 48.scaled)
        }
    }

    var failedView: some View {
        VStack(spacing: 16.scaled) {
            Text("기록을 불러오지 못했어요")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))

            Button("다시 시도") {
                store.send(.task)
            }
            .plobbyFont(.actionLabel)
            .foregroundStyle(Color(.green600))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 게시물 헤더

private extension RecordDetailView {

    func header(_ record: RecordDetail) -> some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            Button {
                store.send(.authorProfileTapped)
            } label: {
                HStack(spacing: 8.scaled) {
                    profileImage(record.profileImageURL)

                    VStack(alignment: .leading, spacing: 2.scaled) {
                        Text(record.nickname)
                            .plobbyFont(.label)

                        Text(Self.relativeTime(record.createdAt))
                            .plobbyFont(.metadata)
                    }
                    .foregroundStyle(Color(.textSecondary))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!record.isMine && store.opensAuthorHome)

            Text(record.title)
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            photoCarousel(record)
        }
    }

    func profileImage(_ url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.fill")
                .font(.system(size: 14.scaled))
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.gray300))
        }
        .frame(width: 32.scaled, height: 32.scaled)
        .clipShape(Circle())
    }

    func photoCarousel(_ record: RecordDetail) -> some View {
        let photos = record.photos

        return ZStack {
            if photos.isEmpty {
                VStack(spacing: 8.scaled) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20.scaled))

                    Text("활동 사진이 없어요")
                        .plobbyFont(.helper)
                }
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.gray50))
            } else {
                TabView(selection: $store.currentPhotoIndex.sending(\.photoPageChanged)) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                        AsyncImage(url: photo.url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color(.gray50)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                LinearGradient(
                    colors: [.clear, Color(.neutralBlack).opacity(0.4)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
        }
        .frame(height: Self.photoHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
        .overlay(alignment: .topTrailing) {
            if !photos.isEmpty {
                Text("\(store.currentPhotoIndex + 1)/\(photos.count)")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.gray0))
                    .frame(width: 44.scaled, height: 26.scaled)
                    .background(Color(.neutralBlack).opacity(0.4), in: RoundedRectangle(cornerRadius: 8.scaled))
                    .padding(12.scaled)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            likeButton(record, isOnPhoto: !photos.isEmpty)
                .padding(.trailing, 12.scaled)
                .padding(.bottom, 8.scaled)
        }
    }

    func likeButton(_ record: RecordDetail, isOnPhoto: Bool) -> some View {
        Button {
            store.send(.likeTapped)
        } label: {
            VStack(spacing: 4.scaled) {
                Image(systemName: record.likedByMe ? "heart.fill" : "heart")
                    .font(.system(size: 26.scaled))
                    .frame(width: 32.scaled, height: 32.scaled)

                Text("\(record.likeCount)")
                    .plobbyFont(.metadata)
            }
            .foregroundStyle(isOnPhoto ? Color(.gray0) : Color(.textSecondary))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(record.likedByMe ? "좋아요 취소" : "좋아요")
        .accessibilityValue("\(record.likeCount)개")
    }
}

// MARK: - 활동 요약

private extension RecordDetailView {

    func summarySection(_ record: RecordDetail) -> some View {
        section("활동 요약") {
            VStack(spacing: 0) {
                summaryRow("활동 날짜", value: Self.dateText(record))
                Divider().overlay(Color(.gray200))
                summaryRow("활동 시간", value: Self.timeText(record))

                if let depth = record.depthM {
                    Divider().overlay(Color(.gray200))
                    summaryRow("최대 수심", value: "\(Self.decimalText(depth))m")
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8.scaled)
                    .stroke(Color(.gray300), lineWidth: 1)
            }
        }
    }

    func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color(.textSecondary))

            Spacer()

            Text(value)
                .foregroundStyle(Color(.textPrimary))
        }
        .plobbyFont(.body)
        .padding(16.scaled)
    }
}

// MARK: - 수거한 쓰레기

private extension RecordDetailView {

    @ViewBuilder
    var trashSection: some View {
        switch store.trashLayout {
        case .hidden:
            EmptyView()

        case let .countAndWeight(totalCount, weight, items):
            trashCard(items: items) {
                HStack(spacing: 24.scaled) {
                    metric("총개수", value: "\(totalCount)개")

                    Rectangle()
                        .fill(Color(.gray200))
                        .frame(width: 1, height: 44.scaled)

                    metric("총무게", value: "\(Self.decimalText(weight))kg")
                }
                .padding(16.scaled)
                .frame(height: 86.scaled)
            }

        case let .countOnly(totalCount, items):
            trashCard(items: items) {
                metricRow("총개수", value: "\(totalCount)개")
            }

        case let .weightOnly(weight):
            trashCard(items: []) {
                metricRow("총무게", value: "\(Self.decimalText(weight))kg")
            }
        }
    }

    func trashCard(
        items: [RecordDetail.Trash],
        @ViewBuilder header: () -> some View
    ) -> some View {
        section("수거한 쓰레기") {
            VStack(spacing: 0) {
                header()
                    .frame(maxWidth: .infinity)
                    .background(Color(.gray50))

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Divider().overlay(Color(.gray300))

                    HStack {
                        Text(item.displayName)
                        Spacer()
                        Text("\(item.quantity)개")
                    }
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textPrimary))
                    .padding(.horizontal, 16.scaled)
                    .frame(height: 56.scaled)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.scaled))
            .overlay {
                RoundedRectangle(cornerRadius: 8.scaled)
                    .stroke(Color(.gray300), lineWidth: 1)
            }
        }
    }

    func metric(_ title: String, value: String) -> some View {
        VStack(spacing: 4.scaled) {
            Text(title)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))

            Text(value)
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))
        }
        .frame(maxWidth: .infinity)
    }

    func metricRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))

            Spacer()

            Text(value)
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))
        }
        .padding(16.scaled)
    }
}

// MARK: - 활동 메모

private extension RecordDetailView {

    @ViewBuilder
    func memoSection(_ record: RecordDetail) -> some View {
        if let memo = record.memo, !InputText.isBlank(memo) {
            section("활동 메모") {
                Text(memo)
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            Text(title)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            content()
        }
    }
}

// MARK: - Format

private extension RecordDetailView {

    static func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    /// 2026.10.23. — 이틀에 걸친 활동이면 2026.10.23. - 2026.10.24.
    static func dateText(_ record: RecordDetail) -> String {
        let start = record.startedAt.formatted(dateStyle)
        guard !Calendar.current.isDate(record.startedAt, inSameDayAs: record.endedAt) else {
            return start
        }
        return "\(start) - \(record.endedAt.formatted(dateStyle))"
    }

    /// 15:00 - 16:00 (1시간 30분)
    static func timeText(_ record: RecordDetail) -> String {
        let minutes = max(Int(record.endedAt.timeIntervalSince(record.startedAt) / 60), 0)
        let hours = minutes / 60
        let remainder = minutes % 60

        let duration = switch (hours, remainder) {
        case (0, _): "\(remainder)분"
        case (_, 0): "\(hours)시간"
        default: "\(hours)시간 \(remainder)분"
        }

        return "\(record.startedAt.formatted(timeStyle)) - \(record.endedAt.formatted(timeStyle)) (\(duration))"
    }

    static func decimalText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    static let dateStyle = Date.VerbatimFormatStyle(
        format: "\(year: .defaultDigits).\(month: .twoDigits).\(day: .twoDigits).",
        timeZone: .current,
        calendar: .current
    )

    static let timeStyle = Date.VerbatimFormatStyle(
        format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
        timeZone: .current,
        calendar: .current
    )
}
