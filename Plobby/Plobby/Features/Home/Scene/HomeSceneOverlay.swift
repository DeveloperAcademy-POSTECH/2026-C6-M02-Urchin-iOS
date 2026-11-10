//
//  HomeSceneOverlay.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeSceneOverlay: View {

    let recordType: RecordType
    let stage: HomeSceneStage
    let day: GoalDailyProgress?
    let totalTrashCount: Int
    let isGoalFinished: Bool
    let onParticipantsTapped: () -> Void
    let onTrashSummaryTapped: () -> Void

    var body: some View {
        ZStack {
            topPills
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 12.scaled)

            participantsButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 20.scaled)
                .padding(.bottom, 14.scaled)
        }
    }
}

// MARK: - Subviews

private extension HomeSceneOverlay {

    @ViewBuilder
    var topPills: some View {
        if isGoalFinished {
            EmptyView()
        } else if isResult {
            resultButton
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
        } else if case .finale = stage {
            EmptyView()
        } else if let day {
            HStack(spacing: 8.scaled) {
                Text(day.day.homeMonthDayText)
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 14.scaled))
                    .foregroundStyle(Color(.textPrimary))
                    .contentTransition(.numericText())
                    .padding(.horizontal, 16.scaled)
                    .frame(height: 32.scaled)
                    .background(Color(.gray0).opacity(0.95), in: Capsule())
                    .homeSceneShadow()

                if stage.isCollected {
                    Text("+\(day.collectedCount)개")
                        .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 13.scaled))
                        .foregroundStyle(Color(.currentBrandText))
                        .padding(.horizontal, 8.scaled)
                        .frame(height: 32.scaled)
                        .background(Color(.currentBrandSubtle), in: Capsule())
                        .homeSceneShadow()
                        .transition(.opacity.combined(with: .scale(scale: 0.6)))
                }
            }
        }
    }

    var resultButton: some View {
        Button(action: onTrashSummaryTapped) {
            HStack(spacing: 4.scaled) {
                Text(recordType.resultTitle)
                    .plobbyFont(.label)
                    .foregroundStyle(Color(.textPrimary))

                Text("\(totalTrashCount)개")
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.currentBrandText))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12.scaled, weight: .semibold))
                    .foregroundStyle(Color(.textPrimary))
            }
            .padding(.horizontal, 16.scaled)
            .frame(height: 36.scaled)
            .background(Color(.gray0).opacity(0.95), in: Capsule())
            .homeSceneShadow()
        }
        .buttonStyle(.plain)
    }

    var participantsButton: some View {
        Button(action: onParticipantsTapped) {
            HStack(spacing: 8.scaled) {
                Text("함께한 사람")
                    .plobbyFont(.label)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12.scaled, weight: .semibold))
            }
            .foregroundStyle(Color(.textPrimary))
            .padding(.horizontal, 16.scaled)
            .frame(height: 44.scaled)
            .background(Color(.gray0), in: Capsule())
            .homeSceneShadow()
        }
        .buttonStyle(.plain)
    }

    var isResult: Bool {
        stage == .finale(step: recordType.resultStep)
    }
}

private extension View {

    func homeSceneShadow() -> some View {
        shadow(color: Color(.neutralBlack).opacity(0.08), radius: 6, y: 2)
    }
}
