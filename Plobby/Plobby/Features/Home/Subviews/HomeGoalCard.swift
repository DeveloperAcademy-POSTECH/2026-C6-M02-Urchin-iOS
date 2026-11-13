//
//  HomeGoalCard.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeGoalCard: View {

    let goal: Goal
    let status: HomeGoalStatus
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRecordTapped: () -> Void
    let onAllGoalsTapped: () -> Void
    /// 튜토리얼에서 펼치기 버튼을 눌러 보라고 동그라미로 강조해요.
    var highlightsToggle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            header

            if showsExpanded {
                Group {
                    HomeGoalMetaRow(goal: goal)
                    progressRow
                    buttons
                }
                .padding(.trailing, 12.scaled)
                .transition(.opacity)
            }
        }
        .padding(.leading, 12.scaled)
        .padding(.vertical, 8.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
        .clipShape(RoundedRectangle(cornerRadius: 8.scaled))
    }
}

// MARK: - Subviews

private extension HomeGoalCard {

    var showsExpanded: Bool {
        isExpanded || status.isFinished
    }

    @ViewBuilder
    var header: some View {
        if status.isFinished {
            headerContent
        } else {
            Button(action: onToggle) {
                headerContent
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "공통 목표 접기" : "공통 목표 펼치기")
            .guestTapAllowed()
        }
    }

    var headerContent: some View {
        HStack(spacing: 8.scaled) {
            VStack(alignment: .leading, spacing: 2.scaled) {
                HStack(spacing: 8.scaled) {
                    Text("공통 목표")
                    Text(status.chipText)
                }
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))

                Text(goal.title)
                    .plobbyFont(.cardTitle)
                    .foregroundStyle(Color(.textPrimary))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !showsExpanded {
                HomeGoalCountText(collected: goal.collectedCount, target: goal.targetCount)
            }

            if !status.isFinished {
                toggleIcon
            }
        }
        .padding(.trailing, status.isFinished ? 12.scaled : 0)
    }

    var progressRow: some View {
        HStack(spacing: 12.scaled) {
            HomeGoalProgressBar(progress: goal.progress, trackColor: Color(.gray300))

            HomeGoalCountText(collected: goal.collectedCount, target: goal.targetCount)
        }
        .frame(height: 20.scaled)
    }

    @ViewBuilder
    var buttons: some View {
        if status.isFinished {
            PlobbyButton(text: "다음 목표 보기", action: onAllGoalsTapped)
        } else {
            VStack(spacing: 0) {
                PlobbyButton(text: "기록하기", action: onRecordTapped)

                Button(action: onAllGoalsTapped) {
                    Text("목표 전체 보기")
                        .plobbyFont(.label)
                        .foregroundStyle(Color(.textSecondary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44.scaled)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    var toggleIcon: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 14.scaled))
            .foregroundStyle(Color(.textSecondary))
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .background {
                if highlightsToggle {
                    Circle()
                        .fill(Color(.surfaceBrandSubtle))
                        .overlay {
                            Circle()
                                .strokeBorder(Color(.textBrand), lineWidth: 1.25)
                        }
                        .frame(width: 40.scaled, height: 40.scaled)
                }
            }
            .padding(.trailing, CGFloat(highlightsToggle ? 13 : 12 - 1.5).scaled)
            .frame(width: 44.scaled, height: 44.scaled, alignment: .trailing)
    }
}
