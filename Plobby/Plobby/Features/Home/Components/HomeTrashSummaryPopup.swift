//
//  HomeTrashSummaryPopup.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 배(플로빙)·수거대(플로깅)에 모은 쓰레기를 종류별로 보여주는 팝업이에요.
struct HomeTrashSummaryPopup: View {

    let board: HomeGoalBoard
    let onClose: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 8.scaled), GridItem(.flexible(), spacing: 8.scaled)]

    var body: some View {
        ZStack {
            Color(.neutralBlack).opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityLabel("닫기")
                .accessibilityAddTraits(.isButton)

            VStack(alignment: .leading, spacing: 12.scaled) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12.scaled) {
                        Text("\(board.goal.recordType.resultTitle) \(board.totalTrashCount)개")
                            .plobbyFont(.heading)
                            .foregroundStyle(Color(.textPrimary))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HomeSheetCloseButton(action: onClose)
                    }

                    Text("\(periodText), \(board.goal.recordType.name)에서 함께 모았어요")
                        .plobbyFont(.label)
                        .foregroundStyle(Color(.textSecondary))
                }

                LazyVGrid(columns: columns, spacing: 8.scaled) {
                    ForEach(board.orderedTrashCounts) { item in
                        cell(item)
                    }
                }
            }
            .padding(.horizontal, 20.scaled)
            .padding(.top, 20.scaled)
            .padding(.bottom, 24.scaled)
            .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 16.scaled))
            .padding(.horizontal, 24.scaled)
        }
    }

    private func cell(_ item: HomeGoalTrashCount) -> some View {
        HStack(spacing: 8.scaled) {
            Image(item.category.homeIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 24.scaled, height: 24.scaled)

            Text(item.category.name)
                .plobbyFont(.label)
                .foregroundStyle(Color(.textPrimary))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(item.count)개")
                .plobbyFont(.labelSelected)
                .foregroundStyle(Color(.textPrimary))
        }
        .padding(8.scaled)
        .frame(height: 40.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
    }

    /// 첫 기록일부터 마지막 기록일까지예요.
    private var periodText: String {
        guard let first = board.days.first?.day, let last = board.days.last?.day else {
            return board.goal.periodText
        }
        return "\(first.homeMonthDayText) ~ \(last.homeMonthDayText)"
    }
}

extension TrashCategory {

    /// 홈 쓰레기 팝업에 쓰는 아이콘이에요.
    var homeIcon: ImageResource {
        switch self {
        case .glass: .glassBottleBrownS
        case .plastic: .bottleWhiteS
        case .metal: .forkGrayS
        case .wood: .woodPieceBrownS
        case .fishingGear: .fishingNetGreenM
        case .clothing: .tshirtPinkS
        case .styrofoam: .styrofoamVer1S
        case .can: .sodaCanMintS
        case .paper: .crumpledPaperWhiteS
        case .rubber: .tireGrayM
        case .etc: .cigaretteButtS
        }
    }
}
