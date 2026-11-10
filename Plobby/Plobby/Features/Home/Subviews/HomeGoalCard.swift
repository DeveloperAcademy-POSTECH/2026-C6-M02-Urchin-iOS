//
//  HomeGoalCard.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 홈 상단 공동 목표 카드예요. 펼치면 기간·참여 인원·진행률·기록하기를, 접으면 제목과 수거량만 보여줘요.
/// 목표가 끝나면 펼친 모양으로 "다음 목표 보기" 버튼을 보여줘요.
struct HomeGoalCard: View {

    let goal: Goal
    let status: HomeGoalStatus
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRecordTapped: () -> Void
    let onAllGoalsTapped: () -> Void

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
            }
        }
        .padding(.leading, 12.scaled)
        .padding(.vertical, 8.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
    }
}

// MARK: - Subviews

private extension HomeGoalCard {

    var showsExpanded: Bool {
        isExpanded || status.isFinished
    }

    /// 펼치기 버튼은 카드 오른쪽 끝에 붙어요. 끝난 목표는 버튼이 없어서 오른쪽 여백을 둬요.
    var header: some View {
        HStack(spacing: 8.scaled) {
            VStack(alignment: .leading, spacing: 2.scaled) {
                HStack(spacing: 8.scaled) {
                    Text("공동 목표")
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
                toggleButton
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

    var toggleButton: some View {
        Button(action: onToggle) {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14.scaled))
                .foregroundStyle(Color(.textSecondary))
                .frame(width: 44.scaled, height: 44.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "공동 목표 접기" : "공동 목표 펼치기")
    }
}
