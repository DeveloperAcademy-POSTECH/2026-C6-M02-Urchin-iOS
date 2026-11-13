//
//  HomeGoalCountText.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// "74 / 200개"처럼 모은 개수와 목표 개수예요.
struct HomeGoalCountText: View {

    let collected: Int
    let target: Int
    var collectedStyle: PlobbyTypography = .labelSelected
    var collectedColor: Color = Color(.currentBrandText)

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4.scaled) {
            Text("\(collected)")
                .plobbyFont(collectedStyle)
                .foregroundStyle(collectedColor)
                .contentTransition(.numericText(value: Double(collected)))

            Text("/ \(target)개")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
        }
        .fixedSize()
    }
}
