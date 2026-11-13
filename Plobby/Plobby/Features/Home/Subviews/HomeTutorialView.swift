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
    let recordType: RecordType
    let onToggleTapped: () -> Void
    let onActivitySwitched: () -> Void
    /// 정해진 시간이 지나 저절로 다음 단계로 넘어갈 때 불려요.
    let onAutoAdvance: () -> Void
    let onFrameChanged: (HomeTutorialTarget, CGRect) -> Void

    @State private var filledGoalCount = Self.goalFillSteps[0]
    @State private var cardHeight: CGFloat = 0
    /// 지금 보이는 카드 높이예요. 카드를 펼치면 날짜 칩이 카드 아래로 따라 내려가요.
    @State private var visibleCardHeight: CGFloat = 0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            scene

            goalCard(isExpanded: false)
                .hidden()
                .accessibilityHidden(true)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    cardHeight = height
                }
                .padding(.horizontal, 20.scaled)

            goalCard(isExpanded: step == .goalFill || step == .goalPeriod)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    visibleCardHeight = height
                }
                .tutorialTarget(.goalCard, onChange: onFrameChanged)
                .padding(.horizontal, 20.scaled)

            activityToggleButton
                .tutorialTarget(.activityToggle, onChange: onFrameChanged)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20.scaled)
                .padding(.bottom, 8.scaled)
        }
        .background(Color(.gray0))
        .task(id: step) {
            switch step {
            case .goalFill: await fillGoal()
            case .goalPeriod: await advance(after: Self.goalPeriodDuration)
            case .recordIntro: await advance(after: Self.recordIntroDuration)
            default: break
            }
        }
    }
}

// MARK: - 홈 화면

private extension HomeTutorialView {

    func goalCard(isExpanded: Bool) -> some View {
        HomeGoalCard(
            goal: Self.goal(collectedCount: goalCollectedCount),
            status: .inProgress(remainingDays: 7),
            isExpanded: isExpanded,
            onToggle: {
                guard step == .goalToggle else { return }
                onToggleTapped()
            },
            onRecordTapped: {},
            onAllGoalsTapped: {},
            onNextGoalTapped: {},
            onParticipantsTapped: {},
            highlightsToggle: step == .goalToggle,
            showsAchievedLabel: goalCollectedCount >= Self.targetCount
        )
    }

    var scene: some View {
        ZStack(alignment: .top) {
            switch recordType {
            case .plogging:
                sceneLayer(backdrop: .homeSceneBeach) {
                    PloggingSceneView(days: [day], stage: sceneStage, collectPulse: collectPulse)
                }
                .transition(.move(edge: .leading))
            case .plobbing:
                sceneLayer(backdrop: .homeSceneSky) {
                    PlobbingSceneView(days: [day], stage: sceneStage, collectPulse: collectPulse)
                }
                .transition(.move(edge: .trailing))
            }

            HomeSceneOverlay(
                recordType: recordType,
                stage: sceneStage,
                day: day,
                totalTrashCount: isTrashCollected ? day.collectedCount : 0,
                isGoalFinished: false,
                isAtDay: true,
                onTrashSummaryTapped: {},
                onPillFrameChanged: { pill, frame in
                    onFrameChanged(pill == .date ? .dayChip : .countChip, frame)
                }
            )
            .padding(.top, max(visibleCardHeight, cardHeight))
            .animation(.easeInOut(duration: 0.25), value: visibleCardHeight)
        }
        .frame(maxHeight: .infinity)
    }

    func sceneLayer<Scene: View>(backdrop: ImageResource, @ViewBuilder scene: () -> Scene) -> some View {
        ZStack(alignment: .top) {
            HomeSceneBackdrop(image: backdrop)
                .ignoresSafeArea()

            scene()
                .padding(.top, cardHeight)
                .ignoresSafeArea(edges: .bottom)
                .tutorialTarget(.scene, onChange: onFrameChanged)
        }
    }

    var activityToggleButton: some View {
        Button {
            guard step == .recordResult, recordType == .plogging else { return }
            onActivitySwitched()
        } label: {
            Image(systemName: recordType == .plogging ? "figure.walk" : "figure.open.water.swim")
                .font(.system(size: 24.scaled))
                .foregroundStyle(Color(.currentBrandText))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 48.scaled, height: 48.scaled)
                .background(Color(.gray0), in: Circle())
                .shadow(color: Color(.neutralBlack).opacity(0.1), radius: 6.scaled, y: 2.scaled)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 단계별 데이터

private extension HomeTutorialView {

    /// 기록 안내 전에는 아직 아무도 기록하지 않은 상태로, 기록 결과부터는 하루치 기록이 더해진 상태로 보여줘요.
    var isTrashCollected: Bool {
        switch step {
        case .goal, .goalToggle, .goalFill, .goalPeriod, .recordIntro, .scroll: false
        case .recordResult, .finish: true
        }
    }

    var goalCollectedCount: Int {
        switch step {
        case .goal, .goalToggle: 0
        case .goalFill: filledGoalCount
        case .goalPeriod: Self.targetCount
        default: isTrashCollected ? day.collectedCount : 0
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

    /// 안내를 정해진 시간 동안 보여준 뒤 저절로 다음 단계로 넘어가요.
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
    static let recordIntroDuration: Duration = .seconds(3)

    static let startDate: Date = {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: .now)
        return calendar.date(from: DateComponents(year: year, month: 11, day: 1)) ?? .now
    }()

    var day: GoalDailyProgress {
        GoalDailyProgress(day: Self.startDate, collectedCount: recordType == .plogging ? 8 : 50, participantCount: 6)
    }

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
