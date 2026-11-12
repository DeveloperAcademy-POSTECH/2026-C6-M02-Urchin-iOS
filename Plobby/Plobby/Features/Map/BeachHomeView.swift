//
//  BeachHomeView.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct BeachHomeView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<BeachHomeFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PlobbyNavigationBar {
                store.send(.backTapped)
            }

            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        Rectangle()
                            .fill(Color(.gray200))
                            .frame(height: 1)
                            .padding(.horizontal, 8)
                            .padding(.top, 24)

                        recordSection
                            .padding(.horizontal, 20)
                            .padding(.top, 32)

                        guardianSection(bottomInset: proxy.safeAreaInsets.bottom)
                            .padding(.top, 16)
                    }
                    .frame(minHeight: proxy.size.height + proxy.safeAreaInsets.bottom, alignment: .top)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Color(.gray0))
        .task {
            await store.send(.task).finish()
        }
        .plobbyAlert(store: store, state: \.alert, action: \.alert)
    }
}

// MARK: - 해변 요약

private extension BeachHomeView {

    var header: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 8) {
                Text(store.beach.name)
                    .font(.custom(PretendardWeight.semiBold.rawValue, size: 24))
                    .foregroundStyle(Color(.textPrimary))

                if store.isMember {
                    Button {
                        store.send(.favoriteTapped)
                    } label: {
                        Image(systemName: store.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(store.isFavorite ? Color(.green500) : Color(.textSecondary))
                            .frame(width: 32, height: 32)
                            .background(Color(.gray50), in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color(.currentWarmBorder), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(store.isFavorite ? "관심 해변 해제" : "관심 해변 등록")
                }
            }

            HStack(spacing: 8) {
                statCard(systemName: "location.fill", title: "정화 활동", value: summaryValue { "\($0.recordCount)회" })
                statCard(systemName: "person.3.fill", title: "참여 인원", value: summaryValue { "\($0.participantCount)명" })
                statCard(systemName: "chart.bar.fill", title: "총 수거량", value: summaryValue { "\($0.totalTrashCount)개" })
            }
        }
    }

    func summaryValue(_ text: (BeachSummary) -> String) -> String {
        switch store.summary {
        case let .loaded(summary): text(summary)
        case .loading, .empty, .failed: "-"
        }
    }

    func statCard(systemName: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(Color(.textSecondary))
                .frame(height: 20)

            Text(title)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))

            Text(value)
                .plobbyFont(.metric)
                .foregroundStyle(Color(.green600))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 활동 기록

private extension BeachHomeView {

    var recordSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("활동 기록")
                    .plobbyFont(.heading)
                    .foregroundStyle(Color(.textPrimary))

                Text("\(store.sortedRecords.count)개")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }

            filterChips

            HStack {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.title) {
                            store.send(.sortOptionChanged(option))
                        }
                    }
                } label: {
                    Text("\(store.sortedRecords.count)개 • \(store.sortOption.title)")
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.textSecondary))
                }

                Spacer()
            }

            records
        }
    }

    var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(RecordFilter.allCases, id: \.self) { filter in
                let isSelected = store.filter == filter

                Button {
                    store.send(.filterTapped(filter))
                } label: {
                    Text(filter.title)
                        .font(.custom(PretendardWeight.semiBold.rawValue, size: 14))
                        .foregroundStyle(isSelected ? Color(.gray0) : Color(.textPrimary))
                        .padding(.horizontal, 16)
                        .frame(height: 36)
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

    @ViewBuilder
    var records: some View {
        switch store.records {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)

        case .empty:
            message("아직 활동 기록이 없어요")

        case .failed:
            message("기록을 불러오지 못했어요")

        case .loaded:
            VStack(spacing: 0) {
                ForEach(store.visibleRecords) { record in
                    recordRow(record)

                    if record.id != store.visibleRecords.last?.id {
                        Rectangle()
                            .fill(Color(.gray200))
                            .frame(height: 1)
                    }
                }
            }

            if store.hasMoreRecords {
                Button {
                    store.send(.moreRecordsTapped, animation: .default)
                } label: {
                    Text("더보기")
                        .plobbyFont(.body)
                        .foregroundStyle(Color(.textSecondary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.currentWarmBorder), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
    }

    func recordRow(_ record: BeachRecord) -> some View {
        Button {
            store.send(.recordTapped(record))
        } label: {
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: record.coverPhotoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(.gray50)
                }
                .frame(width: 108, height: 108)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title)
                        .plobbyFont(.cardTitle)
                        .foregroundStyle(Color(.textPrimary))
                        .lineLimit(1)

                    Text(record.startedAt.formatted(Self.dateStyle))
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.textSecondary))

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        ProfileAvatar(url: record.profileImageURL, size: 24)

                        Text(record.nickname)
                            .plobbyFont(.helper)
                            .foregroundStyle(Color(.textSecondary))
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        if record.likeCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "heart")
                                    .font(.system(size: 11))

                                Text("\(record.likeCount)")
                                    .plobbyFont(.metadata)
                            }
                            .foregroundStyle(Color(.textSecondary))
                        }
                    }
                }
                .frame(height: 108)
            }
            .padding(.vertical, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func message(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    static let dateStyle = Date.VerbatimFormatStyle(
        format: "\(year: .defaultDigits).\(month: .twoDigits).\(day: .twoDigits)",
        timeZone: .current,
        calendar: .current
    )
}

// MARK: - 해변을 지키는 사람들

private extension BeachHomeView {

    @ViewBuilder
    func guardianSection(bottomInset: CGFloat) -> some View {
        if case let .loaded(summary) = store.summary, !summary.guardians.isEmpty {
            let guardians = summary.guardians.prefix(BeachHomeFeature.guardianLimit)

            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Image(systemName: "eyes")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.textSecondary))

                    Text("해변을 지키는 사람들")
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.textSecondary))
                }

                FlowLayout(spacing: 8) {
                    ForEach(guardians) { guardian in
                        guardianChip(nickname: guardian.nickname, url: guardian.profileImageURL)
                    }

                    if summary.guardians.count > guardians.count {
                        guardianChip(nickname: "외", url: nil)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32 + bottomInset)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(
                Color(.gray50),
                in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
            )
        } else {
            Color.clear
                .frame(height: 24 + bottomInset)
        }
    }

    func guardianChip(nickname: String, url: URL?) -> some View {
        HStack(spacing: 8) {
            ProfileAvatar(url: url, size: 24)

            Text(nickname)
                .plobbyFont(.label)
                .foregroundStyle(Color(.textPrimary))
                .lineLimit(1)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .frame(height: 40)
        .background(Color(.gray0), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.currentWarmBorder), lineWidth: 1)
        }
    }
}

// MARK: - ProfileAvatar

private struct ProfileAvatar: View {

    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.5))
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.gray300))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {

    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in rows(for: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextWidth = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width

            if nextWidth > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }

            let isFirst = rows[rows.count - 1].indices.isEmpty
            rows[rows.count - 1].indices.append(index)
            rows[rows.count - 1].width += (isFirst ? 0 : spacing) + size.width
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }
        return rows
    }
}
