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
    @State private var isMoreMenuPresented = false

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
        // 내비게이션 바 바로 아래, 더보기 버튼 오른쪽 끝에 맞춰 펼쳐요.
        .plobbyDropdownMenu(
            isPresented: $isMoreMenuPresented,
            padding: EdgeInsets(top: 56.scaled, leading: 0, bottom: 0, trailing: 20.scaled),
            items: moreMenuItems
        )
        .task {
            await store.send(.task).finish()
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
        .fullScreenCover(item: $store.scope(state: \.editForm, action: \.editForm)) { store in
            RecordFormView(store: store)
        }
        .navigationDestination(item: $store.scope(state: \.report, action: \.report)) { store in
            RecordReportView(store: store)
        }
        .navigationDestination(item: $store.scope(state: \.userHome, action: \.userHome)) { store in
            UserHomeView(store: store)
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

    var moreMenu: some View {
        navigationButton(systemName: "ellipsis", accessibilityLabel: "기록 더보기") {
            isMoreMenuPresented.toggle()
        }
    }

    /// 내 기록은 수정·삭제, 다른 사람 기록은 신고·차단을 보여줘요.
    var moreMenuItems: [PlobbyDropdownMenu.Item] {
        if store.record?.isMine == true {
            [
                .edit { store.send(.moreMenuSelected(.editTapped)) },
                .delete { store.send(.moreMenuSelected(.deleteTapped)) }
            ]
        } else {
            [
                .report { store.send(.moreMenuSelected(.reportTapped)) },
                .block { store.send(.moreMenuSelected(.blockTapped)) }
            ]
        }
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
                .fullScreenCover(
                    isPresented: $store.isPhotoViewerPresented.sending(\.photoViewerPresentationChanged)
                ) {
                    photoViewer(record.photos)
                }
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.send(.photoViewerPresentationChanged(true))
                        }
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

    /// 사진을 화면 가득 원래 비율로 보여줘요. 옆으로 넘기면 상세 화면의 사진도 같이 넘어가요.
    func photoViewer(_ photos: [RecordDetail.Photo]) -> some View {
        ZStack(alignment: .top) {
            Color(.neutralBlack)
                .ignoresSafeArea()

            TabView(selection: $store.currentPhotoIndex.sending(\.photoPageChanged)) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    AsyncImage(url: photo.url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .tint(Color(.gray0))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            HStack(spacing: 0) {
                Button {
                    store.send(.photoViewerPresentationChanged(false))
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20.scaled, weight: .medium))
                        .foregroundStyle(Color(.gray0))
                        .frame(width: 44.scaled, height: 44.scaled)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닫기")

                Spacer(minLength: 0)

                Text("\(store.currentPhotoIndex + 1)/\(photos.count)")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.gray0))
            }
            .padding(.horizontal, 20.scaled)
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
        if let summary = store.trashSummary, !summary.items.isEmpty {
            trashCard(items: summary.items) {
                if let weight = summary.weight {
                    HStack(spacing: 24.scaled) {
                        metric("총개수", value: "\(summary.totalCount)개")

                        Rectangle()
                            .fill(Color(.gray200))
                            .frame(width: 1, height: 44.scaled)

                        metric("총무게", value: "\(Self.decimalText(weight))kg")
                    }
                    .padding(16.scaled)
                    .frame(height: 86.scaled)
                } else {
                    metricRow("총개수", value: "\(summary.totalCount)개")
                }
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
