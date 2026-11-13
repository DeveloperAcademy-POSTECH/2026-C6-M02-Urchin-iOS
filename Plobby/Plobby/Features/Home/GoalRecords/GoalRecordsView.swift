//
//  GoalRecordsView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

struct GoalRecordsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<GoalRecordsFeature>
    @State private var menuRecord: RecordSummary?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PlobbyNavigationBar(title: "수거 기록") {
                store.send(.backButtonTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24.scaled) {
                    goalCard
                    recordsSection
                }
                .padding(.horizontal, 20.scaled)
                .padding(.top, 24.scaled)
                .padding(.bottom, 48.scaled)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.gray0))
        .recordMoreMenu(record: $menuRecord, isMine: { $0.userID == store.memberID }) { record, menu in
            store.send(.recordMenuSelected(record, menu))
        }
        .recordMenu(store: store.scope(state: \.recordMenu, action: \.recordMenu.presented))
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.send(.task).finish()
        }
        .navigationDestination(
            item: $store.scope(state: \.recordDetail, action: \.recordDetail)
        ) { store in
            RecordDetailView(store: store)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Subviews

private extension GoalRecordsView {

    var goalCard: some View {
        let goal = store.goal

        return VStack(alignment: .leading, spacing: 8.scaled) {
            HomeGoalChip(
                text: goal.homeStatus(at: store.now).chipText,
                style: .neutral
            )

            Text(goal.title)
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text(goal.periodText)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))

            HStack(spacing: 12.scaled) {
                HomeGoalProgressBar(progress: goal.progress)
                HomeGoalCountText(collected: goal.collectedCount, target: goal.targetCount)
            }
            .frame(height: 20.scaled)
        }
        .padding(16.scaled)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 12.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 12.scaled)
                .stroke(Color(.gray200), lineWidth: 1.scaled)
        }
    }

    var recordsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("전체 기록")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            RecordFilterChips(selectedFilter: store.recordFilter) { filter in
                store.send(.recordFilterChanged(filter))
            }
            .padding(.top, 12.scaled)

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48.scaled)
            } else if store.filteredRecords.isEmpty {
                Text(store.recordFilter == .all ? "아직 올라온 기록이 없어요" : "해당 유형의 기록이 없어요")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textTertiary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48.scaled)
            } else {
                ForEach(Array(store.filteredRecords.enumerated()), id: \.element.id) { index, record in
                    recordRow(record, showsDivider: index < store.filteredRecords.count - 1)
                }
            }
        }
    }

    static var imageSize: CGFloat { 72 }
    static var rowVerticalPadding: CGFloat { 12 }
    static var titleSpacing: CGFloat { 4 }

    static var moreButtonTop: CGFloat {
        let textHeight = PlobbyTypography.actionLabel.lineHeight + titleSpacing + PlobbyTypography.label.lineHeight
        return rowVerticalPadding + (imageSize - textHeight) / 2
    }

    func recordRow(_ record: RecordSummary, showsDivider: Bool) -> some View {
        let showsMoreButton = store.memberID != nil

        return Button {
            store.send(.recordTapped(record.id))
        } label: {
            HStack(spacing: showsMoreButton ? RecordMoreButton.imageSpacing.scaled : 12.scaled) {
                VStack(alignment: .leading, spacing: Self.titleSpacing.scaled) {
                    Text(record.title)
                        .plobbyFont(.actionLabel)
                        .foregroundStyle(Color(.textPrimary))
                        .lineLimit(1)

                    HStack(spacing: 0) {
                        Text("\(record.nickname) · \(record.createdAt.homeMonthDayText) · ")
                            .foregroundStyle(Color(.textSecondary))
                        Text("+\(record.trashCount)개")
                            .foregroundStyle(Color(.currentBrandText))
                    }
                    .plobbyFont(.label)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, showsMoreButton ? RecordMoreButton.width.scaled : 0)

                AsyncImage(url: record.coverPhotoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(.gray100)
                }
                .frame(width: Self.imageSize.scaled, height: Self.imageSize.scaled)
                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
            }
            .padding(.vertical, Self.rowVerticalPadding.scaled)
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Rectangle()
                        .fill(Color(.gray200))
                        .frame(height: 1.scaled)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if showsMoreButton {
                RecordMoreButton(isMenuPresented: menuRecord?.id == record.id) {
                    menuRecord = record
                }
                .padding(.top, (Self.moreButtonTop - RecordMoreButton.tapInset).scaled)
                .padding(.trailing, (Self.imageSize + RecordMoreButton.imageSpacing).scaled)
            }
        }
    }
}
