//
//  RecordListSection.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import SwiftUI

/// 마이 화면과 타인 홈에서 함께 쓰는 활동 기록 목록이에요. 필터 칩, 개수, 기록 셀을 보여줘요.
/// 기록이 없을 때 보여줄 화면은 `emptyContent`로 바꿀 수 있어요.
struct RecordListSection<EmptyContent: View>: View {

    // MARK: - Properties

    let records: [RecordSummary]
    let selectedFilter: RecordFilter
    let onFilterChanged: (RecordFilter) -> Void
    let onRecordTapped: (RecordSummary.ID) -> Void
    let emptyContent: EmptyContent

    private static var recentDayCount: Int { 7 }

    init(
        records: [RecordSummary],
        selectedFilter: RecordFilter,
        onFilterChanged: @escaping (RecordFilter) -> Void,
        onRecordTapped: @escaping (RecordSummary.ID) -> Void,
        @ViewBuilder emptyContent: () -> EmptyContent
    ) {
        self.records = records
        self.selectedFilter = selectedFilter
        self.onFilterChanged = onFilterChanged
        self.onRecordTapped = onRecordTapped
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

    /// 기록이 없으면 "아직 활동 기록이 없어요"를 보여줘요.
    init(
        records: [RecordSummary],
        selectedFilter: RecordFilter,
        onFilterChanged: @escaping (RecordFilter) -> Void,
        onRecordTapped: @escaping (RecordSummary.ID) -> Void
    ) {
        self.init(
            records: records,
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
            onRecordTapped: onRecordTapped
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
        HStack(alignment: .center, spacing: 8.scaled) {
            ForEach(RecordFilter.allCases, id: \.self) { filter in
                let isSelected = selectedFilter == filter

                Button {
                    onFilterChanged(filter)
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

                if record.id != records.last?.id {
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
}

// MARK: - Format

extension RecordListSection {

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
