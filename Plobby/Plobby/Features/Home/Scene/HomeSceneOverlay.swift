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
    let isAtDay: Bool
    let onTrashSummaryTapped: () -> Void
    /// 날짜 칩과 개수 칩 영역을 화면 좌표로 알려줘요. 튜토리얼에서 칩을 밝게 비출 때 써요.
    var onPillFrameChanged: ((Pill, CGRect) -> Void)?

    enum Pill {
        case date
        case count
    }

    var body: some View {
        topPills
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 12.scaled)
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
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textPrimary))
                    .contentTransition(.numericText(value: day.day.timeIntervalSince1970))
                    .animation(.snappy(duration: 0.35), value: day.day)
                    .padding(.horizontal, 16.scaled)
                    .frame(height: 32.scaled)
                    .background(Color(.gray0).opacity(0.95), in: Capsule())
                    .homeSceneShadow()
                    .reportsFrame { onPillFrameChanged?(.date, $0) }

                if stage.isCollected, isAtDay {
                    HomeCountUpText(count: day.collectedCount)
                        .id(day.day)
                        .plobbyFont(.labelSelected)
                        .foregroundStyle(Color(.currentBrandText))
                        .padding(.horizontal, 8.scaled)
                        .frame(height: 32.scaled)
                        .background(Color(.currentBrandSubtle), in: Capsule())
                        .homeSceneShadow()
                        .reportsFrame { onPillFrameChanged?(.count, $0) }
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

    var isResult: Bool {
        stage == .finale(step: recordType.resultStep)
    }
}

// MARK: - HomeCountUpText

private struct HomeCountUpText: View {

    let count: Int
    @State private var shownCount = 0.0

    var body: some View {
        CountText(value: shownCount)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    shownCount = Double(count)
                }
            }
    }

    private struct CountText: View, Animatable {

        var value: Double

        var animatableData: Double {
            get { value }
            set { value = newValue }
        }

        var body: some View {
            Text("+\(Int(value.rounded()))개")
                .monospacedDigit()
        }
    }
}

private extension View {

    func homeSceneShadow() -> some View {
        shadow(color: Color(.neutralBlack).opacity(0.08), radius: 6.scaled, y: 2.scaled)
    }
}

// MARK: - Frame

private extension View {

    func reportsFrame(_ action: @escaping (CGRect) -> Void) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            action(frame)
        }
    }
}
