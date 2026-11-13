//
//  RecordListSection.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import SwiftUI

struct RecordListSection<EmptyContent: View>: View {

    // MARK: - Properties

    let records: [RecordSummary]
    let selectedFilter: RecordFilter
    let onFilterChanged: (RecordFilter) -> Void
    let onRecordTapped: (RecordSummary.ID) -> Void
    let onMoreTapped: ((RecordSummary) -> Void)?
    let menuRecordID: RecordSummary.ID?
    let emptyContent: EmptyContent

    private static var recentDayCount: Int { 7 }
    private static var imageSize: CGFloat { 108 }

    init(
        records: [RecordSummary],
        selectedFilter: RecordFilter,
        onFilterChanged: @escaping (RecordFilter) -> Void,
        onRecordTapped: @escaping (RecordSummary.ID) -> Void,
        onMoreTapped: ((RecordSummary) -> Void)? = nil,
        menuRecordID: RecordSummary.ID? = nil,
        @ViewBuilder emptyContent: () -> EmptyContent
    ) {
        self.records = records
        self.selectedFilter = selectedFilter
        self.onFilterChanged = onFilterChanged
        self.onRecordTapped = onRecordTapped
        self.onMoreTapped = onMoreTapped
        self.menuRecordID = menuRecordID
        self.emptyContent = emptyContent()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("활동 기록")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            filterChips
                .padding(.top, 12.scaled)

            Text("\(records.count)개")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.gray600))
                .padding(.top, 16.scaled)

            if records.isEmpty {
                emptyContent
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40.scaled)
            } else {
                recordList
            }
        }
    }
}

// MARK: - Empty

extension RecordListSection where EmptyContent == RecordListEmptyMessage {

    init(
        records: [RecordSummary],
        selectedFilter: RecordFilter,
        onFilterChanged: @escaping (RecordFilter) -> Void,
        onRecordTapped: @escaping (RecordSummary.ID) -> Void,
        onMoreTapped: ((RecordSummary) -> Void)? = nil,
        menuRecordID: RecordSummary.ID? = nil
    ) {
        self.init(
            records: records,
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
            onRecordTapped: onRecordTapped,
            onMoreTapped: onMoreTapped,
            menuRecordID: menuRecordID
        ) {
            RecordListEmptyMessage()
        }
    }
}

struct RecordListEmptyMessage: View {

    var body: some View {
        Text("아직 활동 기록이 없어요")
            .plobbyFont(.label)
            .foregroundStyle(Color(.textTertiary))
    }
}

// MARK: - 필터

extension RecordListSection {

    private var filterChips: some View {
        RecordFilterChips(selectedFilter: selectedFilter, onFilterChanged: onFilterChanged)
    }
}

// MARK: - 기록 목록

extension RecordListSection {

    private var recordList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(records) { record in
                Button {
                    onRecordTapped(record.id)
                } label: {
                    recordRow(record)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .topTrailing) {
                    if let onMoreTapped {
                        RecordMoreButton(isMenuPresented: menuRecordID == record.id) {
                            onMoreTapped(record)
                        }
                        .padding(.top, (16 - RecordMoreButton.tapInset).scaled)
                        .padding(.trailing, (Self.imageSize + RecordMoreButton.imageSpacing).scaled)
                    }
                }

                if record.id != records.last?.id {
                    Divider()
                }
            }
        }
    }

    private func recordRow(_ record: RecordSummary) -> some View {
        HStack(alignment: .top, spacing: RecordMoreButton.imageSpacing.scaled) {
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
            .padding(.trailing, onMoreTapped == nil ? 0 : RecordMoreButton.width.scaled)

            AsyncImage(url: record.coverPhotoURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.gray50)
            }
            .frame(width: Self.imageSize.scaled, height: Self.imageSize.scaled)
            .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
        }
        .frame(height: Self.imageSize.scaled)
        .padding(.vertical, 16.scaled)
    }
}

// MARK: - Format

extension RecordListSection {

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

// MARK: - RecordMoreButton

struct RecordMoreButton: View {

    let isMenuPresented: Bool
    let action: () -> Void

    static var width: CGFloat { 24 }
    static var imageSpacing: CGFloat { 32 }
    static var height: CGFloat { PlobbyTypography.actionLabel.lineHeight }
    static var tapSize: CGFloat { 44 }
    /// 터치 영역이 아이콘보다 위아래로 넓어진 만큼이에요. 위치를 잡을 때 이만큼 올려요.
    static var tapInset: CGFloat { (tapSize - height) / 2 }

    var body: some View {
        Button(action: action) {
            Image(systemName: "ellipsis")
                .font(.system(size: 13.scaled, weight: .semibold))
                .foregroundStyle(Color(.gray600))
                .frame(width: Self.width.scaled, height: Self.height.scaled, alignment: .trailing)
                .plobbyDropdownAnchor(isPresented: isMenuPresented)
                .frame(width: Self.tapSize.scaled, height: Self.tapSize.scaled, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("기록 더보기")
    }
}
