//
//  HomeGoalChip.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 목표 상태 칩이에요. (공동 목표, D-7, 목표 달성, 기간 종료)
struct HomeGoalChip: View {

    enum Style {
        case brand
        case neutral
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .plobbyFont(.metadata)
            .foregroundStyle(style == .brand ? Color(.currentBrandText) : Color(.textSecondary))
            .padding(.horizontal, 8.scaled)
            .padding(.vertical, 2.scaled)
            .background(
                style == .brand ? Color(.currentBrandSubtle) : Color(.gray50),
                in: RoundedRectangle(cornerRadius: 8.scaled)
            )
    }
}
