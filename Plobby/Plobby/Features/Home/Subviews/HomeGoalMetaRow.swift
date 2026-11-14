//
//  HomeGoalMetaRow.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// "11월 1일 ~ 11월 14일 | 18명 참여"예요.
/// `onParticipantsTapped`를 넘기면 "n명 참여"가 초록색 버튼이 돼요.
struct HomeGoalMetaRow: View {

    let goal: Goal
    var showsIcons = true
    var onParticipantsTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: 8.scaled) {
            label(goal.periodText, systemImage: "calendar")

            Rectangle()
                .fill(Color(.gray200))
                .frame(width: 1.scaled, height: 12.scaled)

            participants
        }
        .foregroundStyle(Color(.textSecondary))
    }

    @ViewBuilder
    private var participants: some View {
        let text = "\(goal.participantCount)명 참여"

        if let onParticipantsTapped {
            Button(action: onParticipantsTapped) {
                HStack(spacing: 4.scaled) {
                    if showsIcons {
                        Image(systemName: "person.fill")
                            .font(.system(size: 13.scaled))
                    }
                    Text(text)
                        .plobbyFont(.helper)
                        .underline()
                        .foregroundStyle(Color(.currentBrandText))
                }
                .frame(minHeight: 44.scaled)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -12.scaled)
            .accessibilityLabel("함께한 사람 \(text)")
        } else {
            label(text, systemImage: "person.fill")
        }
    }

    private func label(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4.scaled) {
            if showsIcons {
                Image(systemName: systemImage)
                    .font(.system(size: 13.scaled))
            }
            Text(text)
                .plobbyFont(.helper)
        }
    }
}
