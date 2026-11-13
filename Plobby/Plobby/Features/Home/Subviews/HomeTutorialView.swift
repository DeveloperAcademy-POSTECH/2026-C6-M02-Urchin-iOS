//
//  HomeTutorialView.swift
//  Plobby
//
//  Created by 이은지 on 11/13/26.
//

import SwiftUI

/// 홈 튜토리얼 화면이에요. 실제 데이터 대신 시안의 정해진 데이터로 홈을 그려요.
/// 안내 막은 탭바까지 덮어야 해서 메인 탭에서 `HomeTutorialOverlay`로 따로 그리고, 여기서는 비출 영역만 알려줘요.
struct HomeTutorialView: View {

    // MARK: - Properties

    let step: HomeTutorialStep
    let onToggleTapped: () -> Void
    /// 정해진 시간이 지나 저절로 다음 단계로 넘어갈 때 불려요.
    let onAutoAdvance: () -> Void
    let onFrameChanged: (HomeTutorialTarget, CGRect) -> Void

    @State private var filledGoalCount = Self.goalFillSteps[0]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            HomeGoalCard(
                goal: Self.goal(collectedCount: goalCollectedCount),
                status: .inProgress(remainingDays: 7),
                isExpanded: step == .goalFill || step == .goalPeriod,
                onToggle: {
                    guard step == .goalToggle else { return }
                    onToggleTapped()
                },
                onRecordTapped: {},
                onAllGoalsTapped: {},
                highlightsToggle: step == .goalToggle,
                showsAchievedLabel: goalCollectedCount >= Self.targetCount
            )
            .tutorialTarget(.goalCard, onChange: onFrameChanged)
            .padding(.horizontal, 20.scaled)

            activityTabs
                .tutorialTarget(.activityTabs, onChange: onFrameChanged)
                .padding(.top, 4.scaled)

            scene
                .tutorialTarget(.scene, onChange: onFrameChanged)
        }
        .background(Color(.gray0))
        .task(id: step) {
            switch step {
            case .goalFill: await fillGoal()
            case .goalPeriod: await advance(after: Self.goalPeriodDuration)
            default: break
            }
        }
    }
}

// MARK: - 홈 화면

private extension HomeTutorialView {

    var header: some View {
        HStack {
            Image(.homeLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 73.scaled, height: 23.scaled)

            Spacer()

            Image(.bell)
                .resizable()
                .scaledToFit()
                .frame(width: 24.scaled, height: 24.scaled)
                .frame(width: 44.scaled, height: 44.scaled)
        }
        .padding(.leading, 20.scaled)
        .padding(.trailing, 12.scaled)
        .frame(height: 50.scaled)
    }

    var activityTabs: some View {
        HStack(spacing: 0) {
            activityTab(RecordType.plogging.name, isSelected: true)
            activityTab(RecordType.plobbing.name, isSelected: false)
        }
        .padding(.bottom, 4.scaled)
        .background(Color(.gray0))
    }

    func activityTab(_ title: String, isSelected: Bool) -> some View {
        Text(title)
            .plobbyFont(isSelected ? .actionLabel : .body)
            .foregroundStyle(isSelected ? Color(.textPrimary) : Color(.textSecondary))
            .frame(maxWidth: .infinity)
            .frame(height: 48.scaled)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(Color(.green500))
                        .frame(height: 4.scaled)
                        .offset(y: 4.scaled)
                }
            }
    }

    var scene: some View {
        ZStack {
            PloggingSceneView(days: [Self.day], stage: sceneStage, collectPulse: collectPulse, walkProgress: 0)
                .ignoresSafeArea(edges: .bottom)

            HomeSceneOverlay(
                recordType: .plogging,
                stage: sceneStage,
                day: Self.day,
                totalTrashCount: isTrashCollected ? Self.day.collectedCount : 0,
                isGoalFinished: false,
                isAtDay: true,
                onParticipantsTapped: {},
                onTrashSummaryTapped: {}
            )

            Image(systemName: "plus")
                .font(.system(size: 24.scaled, weight: .medium))
                .foregroundStyle(Color(.currentBrandText))
                .frame(width: 56.scaled, height: 56.scaled)
                .background(Color(.gray0), in: Circle())
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20.scaled)
                .padding(.bottom, 8.scaled)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - 단계별 데이터

private extension HomeTutorialView {

    /// 기록 안내 전에는 아직 아무도 기록하지 않은 상태로, 기록 결과부터는 하루치 기록이 더해진 상태로 보여줘요.
    var isTrashCollected: Bool {
        switch step {
        case .goal, .goalToggle, .goalFill, .goalPeriod, .recordIntro: false
        case .recordResult, .scroll, .activitySwitch, .finish: true
        }
    }

    var goalCollectedCount: Int {
        switch step {
        case .goal, .goalToggle: 0
        case .goalFill: filledGoalCount
        case .goalPeriod: Self.targetCount
        default: isTrashCollected ? Self.day.collectedCount : 0
        }
    }

    /// 카드가 펼쳐지면 50 → 150 → 200개로 차오르고, 다 차고 잠시 뒤 목표 기간 안내로 넘어가요.
    func fillGoal() async {
        filledGoalCount = Self.goalFillSteps[0]
        for count in Self.goalFillSteps.dropFirst() {
            try? await Task.sleep(for: Self.goalFillInterval)
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.5)) {
                filledGoalCount = count
            }
        }

        await advance(after: Self.goalFilledDelay)
    }

    /// 목표 기간 안내는 잠시 보여준 뒤 저절로 넘어가요. 다음 단계에서는 카드가 접혀요.
    func advance(after duration: Duration) async {
        try? await Task.sleep(for: duration)
        guard !Task.isCancelled else { return }

        onAutoAdvance()
    }

    var sceneStage: HomeSceneStage {
        isTrashCollected ? .collected(day: 0) : .arrived(day: 0)
    }

    var collectPulse: Int {
        isTrashCollected ? 1 : 0
    }
}

// MARK: - 시안 데이터

private extension HomeTutorialView {

    static let targetCount = 200
    static let goalFillSteps = [50, 150, 200]
    static let goalFillInterval: Duration = .seconds(0.8)
    static let goalFilledDelay: Duration = .seconds(0.5)
    static let goalPeriodDuration: Duration = .seconds(3)

    static let startDate: Date = {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: .now)
        return calendar.date(from: DateComponents(year: year, month: 11, day: 1)) ?? .now
    }()

    static let day = GoalDailyProgress(day: startDate, collectedCount: 8, participantCount: 6)

    static func goal(collectedCount: Int) -> Goal {
        Goal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000177") ?? UUID(),
            title: "해양 쓰레기 줍기",
            targetCount: targetCount,
            startsAt: startDate,
            endsAt: Calendar.current.date(byAdding: .day, value: 14, to: startDate) ?? startDate,
            achievedAt: nil,
            collectedCount: collectedCount,
            ploggingCollectedCount: collectedCount,
            plobbingCollectedCount: 0,
            participantCount: 18,
            ploggingParticipantCount: 18,
            plobbingParticipantCount: 0
        )
    }
}

// MARK: - 강조 영역

private extension View {

    /// 튜토리얼에서 밝게 비출 영역을 화면 좌표로 기록해요.
    func tutorialTarget(_ target: HomeTutorialTarget, onChange: @escaping (HomeTutorialTarget, CGRect) -> Void) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            onChange(target, frame)
        }
    }
}
