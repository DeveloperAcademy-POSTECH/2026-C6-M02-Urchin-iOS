//
//  HomeGoalMetaRow.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// "11월 1일 ~ 11월 14일 | 18명 참여"예요.
struct HomeGoalMetaRow: View {

    let goal: Goal
    var showsIcons = true

    var body: some View {
        HStack(spacing: 8.scaled) {
            label(goal.periodText, systemImage: "calendar")

            Rectangle()
                .fill(Color(.gray200))
                .frame(width: 1.scaled, height: 12.scaled)

            label("\(goal.participantCount)명 참여", systemImage: "person.fill")
        }
        .foregroundStyle(Color(.textSecondary))
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
