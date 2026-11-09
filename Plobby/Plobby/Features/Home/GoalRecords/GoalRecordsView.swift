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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HomeNavigationBar(title: "수거 기록") {
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
        .toolbar(.hidden, for: .navigationBar)
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
                text: goal.status(now: store.now, calendar: Calendar(identifier: .gregorian)).chipText,
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
                .stroke(Color(.gray200), lineWidth: 1)
        }
    }

    var recordsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("전체 기록")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            if store.records.isEmpty {
                Text("아직 올라온 기록이 없어요")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textTertiary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48.scaled)
            } else {
                ForEach(Array(store.records.enumerated()), id: \.element.id) { index, record in
                    recordRow(record, showsDivider: index < store.records.count - 1)
                }
            }
        }
    }

    func recordRow(_ record: HomeGoalRecord, showsDivider: Bool) -> some View {
        Button {
            store.send(.recordTapped(record.id))
        } label: {
            HStack(spacing: 12.scaled) {
                VStack(alignment: .leading, spacing: 4.scaled) {
                    Text(record.title)
                        .plobbyFont(.actionLabel)
                        .foregroundStyle(Color(.textPrimary))
                        .lineLimit(1)

                    HStack(spacing: 0) {
                        Text("\(record.nickname) · \(record.createdAt.homeMonthDayText) · ")
                            .foregroundStyle(Color(.textSecondary))
                        Text("+\(record.collectedCount)개")
                            .foregroundStyle(Color(.currentBrandText))
                    }
                    .plobbyFont(.label)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AsyncImage(url: record.thumbnailURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(.gray100)
                }
                .frame(width: 72.scaled, height: 72.scaled)
                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
            }
            .padding(.vertical, 12.scaled)
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
    }
}
