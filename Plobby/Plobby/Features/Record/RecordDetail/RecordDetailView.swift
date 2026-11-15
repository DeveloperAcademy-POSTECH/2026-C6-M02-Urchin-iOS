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
    @State private var isPhotoZoomed = false
    @Namespace private var photoTransition

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
        .plobbyDropdownMenu(
            isPresented: $isMoreMenuPresented,
            padding: EdgeInsets(top: 56.scaled, leading: 0, bottom: 0, trailing: 20.scaled),
            items: moreMenuItems
        )
        .task {
            await store.send(.task).finish()
        }
        .plobbyAlert(store: store, state: \.alert, action: \.alert)
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
        PlobbyNavigationBar(title: "기록 상세", isTrailingEnabled: store.record != nil) {
            store.send(.backTapped)
        } trailingAction: {
            isMoreMenuPresented.toggle()
        } trailingLabel: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17.scaled, weight: .medium))
                .foregroundStyle(Color(.textPrimary))
                .opacity(store.record == nil ? 0 : 1)
                .accessibilityLabel("기록 더보기")
        }
    }

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
                        .matchedTransitionSource(id: index, in: photoTransition) { source in
                            source.clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                        }
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

    /// 사진 앱처럼 누른 사진에서 커지며 열리고, 아래로 끌어내리면 그 사진 자리로 줄어들며 닫혀요.
    /// 확대한 상태에서는 사진을 둘러봐야 하니 끌어서 닫히지 않게 막아요.
    func photoViewer(_ photos: [RecordDetail.Photo]) -> some View {
        ZStack(alignment: .top) {
            Color(.neutralBlack)
                .ignoresSafeArea()

            TabView(selection: $store.currentPhotoIndex.sending(\.photoPageChanged)) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    ZoomablePhoto(url: photo.url, isZoomed: $isPhotoZoomed)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .scrollDisabled(isPhotoZoomed)
            .ignoresSafeArea()

            photoViewerHeader(photos)
        }
        .navigationTransition(.zoom(sourceID: store.currentPhotoIndex, in: photoTransition))
        .interactiveDismissDisabled(isPhotoZoomed)
        .onAppear {
            isPhotoZoomed = false
        }
    }

    func photoViewerHeader(_ photos: [RecordDetail.Photo]) -> some View {
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

    static func dateText(_ record: RecordDetail) -> String {
        let start = record.startedAt.formatted(dateStyle)
        guard !Calendar.current.isDate(record.startedAt, inSameDayAs: record.endedAt) else {
            return start
        }
        return "\(start) - \(record.endedAt.formatted(dateStyle))"
    }

    static func timeText(_ record: RecordDetail) -> String {
        let minutes = max(Int(record.endedAt.timeIntervalSince(record.startedAt) / 60), 0)
        return "\(record.startedAt.formatted(timeStyle)) - \(record.endedAt.formatted(timeStyle)) (\(durationText(minutes: minutes)))"
    }

    static func durationText(minutes: Int) -> String {
        let days = minutes / (24 * 60)
        let hours = minutes % (24 * 60) / 60
        let remainder = minutes % 60

        guard days == 0 else {
            return hours == 0 ? "\(days)일" : "\(days)일 \(hours)시간"
        }

        return switch (hours, remainder) {
        case (0, _): "\(remainder)분"
        case (_, 0): "\(hours)시간"
        default: "\(hours)시간 \(remainder)분"
        }
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

// MARK: - ZoomablePhoto

/// 사진 자세히 보기의 한 장이에요. 두 손가락으로 확대하고, 확대한 상태에서는 끌어서 둘러봐요.
private struct ZoomablePhoto: View {

    // MARK: - Properties

    let url: URL?
    @Binding var isZoomed: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private static let maxScale: CGFloat = 4
    private static let doubleTapScale: CGFloat = 2.5

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView()
                    .tint(Color(.gray0))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                toggleZoom()
            }
            .gesture(magnifyGesture(in: proxy.size))
            .gesture(panGesture(in: proxy.size), including: isZoomed ? .all : .subviews)
        }
        .onDisappear {
            reset()
        }
    }
}

// MARK: - Gestures

private extension ZoomablePhoto {

    func magnifyGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), Self.maxScale)
                isZoomed = scale > 1
            }
            .onEnded { _ in
                guard scale > 1 else {
                    withAnimation(.spring(duration: 0.3)) { reset() }
                    return
                }

                lastScale = scale
                withAnimation(.spring(duration: 0.3)) {
                    offset = clamped(offset, in: size)
                }
                lastOffset = offset
            }
    }

    func panGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                withAnimation(.spring(duration: 0.3)) {
                    offset = clamped(offset, in: size)
                }
                lastOffset = offset
            }
    }
}

// MARK: - Zoom

private extension ZoomablePhoto {

    func toggleZoom() {
        withAnimation(.spring(duration: 0.3)) {
            guard scale == 1 else {
                reset()
                return
            }

            scale = Self.doubleTapScale
            lastScale = scale
            isZoomed = true
        }
    }

    /// 확대한 사진이 화면 밖으로 너무 벗어나지 않게, 늘어난 만큼만 움직일 수 있게 해요.
    func clamped(_ offset: CGSize, in size: CGSize) -> CGSize {
        let maxX = size.width * (scale - 1) / 2
        let maxY = size.height * (scale - 1) / 2
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }

    func reset() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        isZoomed = false
    }
}
