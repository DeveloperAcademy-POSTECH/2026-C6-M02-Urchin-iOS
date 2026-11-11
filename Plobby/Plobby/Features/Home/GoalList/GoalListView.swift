//
//  GoalListView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

struct GoalListView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<GoalListFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PlobbyNavigationBar(title: "공통 목표") {
                store.send(.backButtonTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24.scaled) {
                    infoBanner

                    if store.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48.scaled)
                    } else {
                        if let currentGoal = store.currentGoal {
                            currentGoalSection(currentGoal)
                        }

                        if !store.pastGoals.isEmpty {
                            pastGoalsSection
                        }
                    }
                }
                .padding(.horizontal, 20.scaled)
                .padding(.top, 24.scaled)
                .padding(.bottom, 48.scaled)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color(.gray0))
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.send(.task).finish()
        }
        .navigationDestination(
            item: $store.scope(state: \.goalRecords, action: \.goalRecords)
        ) { store in
            GoalRecordsView(store: store)
        }
    }
}

// MARK: - Subviews

private extension GoalListView {

    var infoBanner: some View {
        HStack(spacing: 8.scaled) {
            Image(systemName: "info.circle")
                .font(.system(size: 16.scaled, weight: .medium))

            Text("플로깅과 플로빙의 수거 개수를 합쳐요")
                .plobbyFont(.label)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(.textSecondary))
        .padding(12.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
    }

    func currentGoalSection(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("진행 중인 목표")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            currentGoalCard(goal)
        }
    }

    func currentGoalCard(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            HStack(spacing: 12.scaled) {
                Text(goal.title)
                    .plobbyFont(.heading)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HomeGoalChip(
                    text: goal.homeStatus(at: store.now).chipText,
                    style: .neutral
                )
            }

            VStack(alignment: .leading, spacing: 8.scaled) {
                HomeGoalCountText(
                    collected: goal.collectedCount,
                    target: goal.targetCount,
                    collectedStyle: .heading
                )

                HomeGoalProgressBar(progress: goal.progress)
            }

            HomeGoalMetaRow(goal: goal)

            Button {
                store.send(.currentGoalRecordsTapped)
            } label: {
                HStack(spacing: 4.scaled) {
                    Text("수거 기록 보기")
                        .plobbyFont(.label)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14.scaled, weight: .medium))
                }
                .foregroundStyle(Color(.currentBrandText))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(16.scaled)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 12.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 12.scaled)
                .stroke(Color(.gray200), lineWidth: 1)
        }
    }

    var pastGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("지난 목표")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            VStack(spacing: 0) {
                ForEach(Array(store.pastGoals.enumerated()), id: \.element.id) { index, goal in
                    if index > 0 {
                        Rectangle()
                            .fill(Color(.gray200))
                            .frame(height: 1.scaled)
                    }

                    pastGoalRow(goal)
                }
            }
        }
    }

    func pastGoalRow(_ goal: Goal) -> some View {
        let isAchieved = goal.status(at: store.now) == .achieved

        return Button {
            store.send(.pastGoalTapped(goal.id))
        } label: {
            HStack(spacing: 8.scaled) {
                VStack(alignment: .leading, spacing: 8.scaled) {
                    HomeGoalChip(
                        text: isAchieved ? "목표 달성" : "기간 종료",
                        style: isAchieved ? .brand : .neutral
                    )

                    Text(goal.title)
                        .plobbyFont(.cardTitle)
                        .foregroundStyle(Color(.textPrimary))

                    HomeGoalCountText(
                        collected: goal.collectedCount,
                        target: goal.targetCount,
                        collectedColor: Color(.textPrimary)
                    )

                    HomeGoalMetaRow(goal: goal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14.scaled, weight: .medium))
                    .foregroundStyle(Color(.textSecondary))
            }
            .padding(.vertical, 8.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
