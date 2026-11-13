//
//  HomeTutorialOverlay.swift
//  Plobby
//
//  Created by 이은지 on 11/13/26.
//

import SwiftUI

// MARK: - HomeTutorialStep

enum HomeTutorialStep: CaseIterable, Equatable {
    case goal
    case goalToggle
    case goalFill
    case goalPeriod
    case recordIntro
    case scroll
    case recordResult
    case finish

    var next: Self? {
        let steps = Self.allCases
        guard let index = steps.firstIndex(of: self), index + 1 < steps.count else { return nil }
        return steps[index + 1]
    }

    var message: String? {
        switch self {
        case .goal: "우리가 플로깅과 플로빙으로 함께 채워 가는 목표예요"
        case .goalToggle: "공통 목표를 눌러 보세요"
        case .goalFill: nil
        case .goalPeriod: "기간이 끝나거나 목표가 달성되면 새 목표가 시작돼요"
        case .recordIntro: "기록이 쌓이면 어떻게 보일까요?"
        case .recordResult: "이렇게 기록하면 공통 목표에 포함돼요"
        case .scroll: "스크롤해 보세요"
        case .finish: nil
        }
    }

    var showsCountChip: Bool {
        switch self {
        case .recordResult, .finish: true
        default: false
        }
    }

    var showsActivityToggle: Bool {
        self == .recordResult
    }

    var target: HomeTutorialTarget? {
        switch self {
        case .goal, .goalToggle, .goalFill, .goalPeriod: .goalCard
        case .recordIntro, .recordResult, .scroll: .scene
        case .finish: nil
        }
    }
}

enum HomeTutorialTarget: Hashable {
    case goalCard
    case activityToggle
    case dayChip
    case countChip
    case scene
}

// MARK: - HomeTutorialOverlay

/// 홈 위를 어둡게 덮고 단계마다 한 곳만 밝게 비춰요. 아무 곳이나 누르면 다음 단계로 넘어가요.
struct HomeTutorialOverlay: View {

    // MARK: - Properties

    let step: HomeTutorialStep
    let recordType: RecordType
    /// 화면 좌표(global)로 잰 강조할 영역이에요.
    let frames: [HomeTutorialTarget: CGRect]
    let onAdvance: () -> Void
    let onFinish: () -> Void

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let highlight = step.target
                .flatMap { frames[$0] }
                .map { $0.offsetBy(dx: -origin.x, dy: -origin.y) }
            let dayChip = step.target == .scene
                ? frames[.dayChip].map { $0.offsetBy(dx: -origin.x, dy: -origin.y) }
                : nil
            let countChip = step.target == .scene && step.showsCountChip
                ? frames[.countChip].map { $0.offsetBy(dx: -origin.x, dy: -origin.y) }
                : nil
            let isSwitchable = step == .recordResult && recordType == .plogging
            let activityToggle = step.showsActivityToggle
                ? frames[.activityToggle].map { $0.offsetBy(dx: -origin.x, dy: -origin.y) }
                : nil
            let goalCard = step.target == .scene
                ? frames[.goalCard].map { $0.offsetBy(dx: -origin.x, dy: -origin.y) }
                : nil

            ZStack(alignment: .top) {
                if step == .finish {
                    finishView
                } else {
                    dimmedBackground(
                        highlight: highlight,
                        chips: [dayChip, countChip].compactMap { $0 },
                        goalCard: goalCard,
                        activityToggle: activityToggle
                    )

                    if let message = step.message {
                        caption(message, highlight: highlight, dayChip: dayChip)
                            .id(message)
                            .transition(.opacity)
                    }

                    if step == .scroll {
                        // VoiceOver에서는 드래그가 전달되지 않을 수 있어서 활성화나 스크롤 동작으로도 넘어가요.
                        HomeTutorialScrollHint()
                            .accessibilityElement()
                            .accessibilityLabel("스크롤해 보세요")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction { onAdvance() }
                            .accessibilityScrollAction { _ in onAdvance() }
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }

                    if let activityToggle {
                        HomeTutorialBouncingLabel(text: "\((recordType == .plogging ? RecordType.plobbing : .plogging).name) 보기")
                            .position(
                                x: activityToggle.midX,
                                y: activityToggle.minY - 24.scaled - PlobbyTypography.labelSelected.lineHeight.scaled / 2
                            )
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            // 펼치기 안내는 목표 카드만, 플로깅 기록 결과는 전환 버튼만 눌리게 비워 두고, 나머지 영역은 눌러도 넘어가지 않아요.
            .contentShape(TapArea(hole: step == .goalToggle ? highlight : isSwitchable ? activityToggle : nil), eoFill: true)
            .onTapGesture {
                guard ![.goalToggle, .goalFill, .scroll, .finish].contains(step), !isSwitchable else { return }
                onAdvance()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        guard step == .scroll, value.translation.height < -Self.scrollThreshold.scaled else { return }
                        onAdvance()
                    }
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - 어두운 막

private extension HomeTutorialOverlay {

    func dimmedBackground(highlight: CGRect?, chips: [CGRect], goalCard: CGRect?, activityToggle: CGRect?) -> some View {
        Color(.neutralBlack)
            .opacity(0.6)
            .mask {
                ZStack {
                    Rectangle()

                    if let highlight {
                        hole(highlight)
                            .blendMode(.destinationOut)
                    }

                    ForEach(chips.indices, id: \.self) { index in
                        Capsule()
                            .frame(width: chips[index].width, height: chips[index].height)
                            .position(x: chips[index].midX, y: chips[index].midY)
                            .blendMode(.destinationOut)
                    }

                    if let goalCard {
                        RoundedRectangle(cornerRadius: 16.scaled)
                            .frame(width: goalCard.width, height: goalCard.height)
                            .position(x: goalCard.midX, y: goalCard.midY)
                            .blendMode(.destinationOut)
                    }

                    if let activityToggle {
                        Circle()
                            .frame(width: activityToggle.width, height: activityToggle.height)
                            .position(x: activityToggle.midX, y: activityToggle.midY)
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
            }
    }

    @ViewBuilder
    func hole(_ rect: CGRect) -> some View {
        switch step.target {
        case .scene:
            let diameter = Self.spotlightDiameter.scaled

            Circle()
                .frame(width: diameter, height: diameter)
                .blur(radius: 24)
                .position(spotlightCenter(in: rect))

        default:
            RoundedRectangle(cornerRadius: 16.scaled)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }

    func caption(_ message: String, highlight: CGRect?, dayChip: CGRect?) -> some View {
        Text(message)
            .plobbyFont(.actionLabel)
            .foregroundStyle(Color(.gray0))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24.scaled)
            .padding(.top, captionTop(highlight: highlight, dayChip: dayChip))
    }

    func captionTop(highlight: CGRect?, dayChip: CGRect?) -> CGFloat {
        if let dayChip {
            return dayChip.maxY + 12.scaled
        }
        guard let highlight else { return 160.scaled }

        switch step.target {
        case .scene: return highlight.minY + 56.scaled
        default: return highlight.maxY + 16.scaled
        }
    }

    /// 장면 속 사람(잠수부) 무리의 가운데예요. 장면은 시안 폭(402) 좌표로 그려서, 같은 좌표에 배율만 곱해요.
    func spotlightCenter(in scene: CGRect) -> CGPoint {
        let point = Self.groupCenter(recordType: recordType, isCollected: step.showsCountChip)
        let scale = scene.width / DesignScale.frameWidth
        return CGPoint(x: scene.minX + point.x * scale, y: scene.minY + point.y * scale)
    }

    /// 플로깅은 `PloggingSceneView.Metrics.humans`, 플로빙은 `PlobbingSceneView.Metrics.diverGroup`의 가운데예요.
    /// 플로빙은 쓰레기를 담으면 잠수부가 아래로 내려가서(`collectDive`) 그만큼 따라 내려가요.
    static func groupCenter(recordType: RecordType, isCollected: Bool) -> CGPoint {
        switch recordType {
        case .plogging: CGPoint(x: 284, y: 165)
        case .plobbing: CGPoint(x: 185, y: isCollected ? 303 : 248)
        }
    }

    static let spotlightDiameter: CGFloat = 260
    static let scrollThreshold: CGFloat = 40
}

// MARK: - 마무리

private extension HomeTutorialOverlay {

    var finishView: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, Color(.neutralBlack).opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 24.scaled) {
                Text("함께 바다를\n지키러 가볼까요?")
                    .plobbyFont(.headingLarge)
                    .foregroundStyle(Color(.gray0))
                    .frame(maxWidth: .infinity, alignment: .leading)

                PlobbyButton(text: "홈으로 가기", action: onFinish)
            }
            .padding(.horizontal, 20.scaled)
            .padding(.bottom, 58.scaled)
        }
    }
}

// MARK: - HomeTutorialScrollHint

/// 화면 가운데에서 아래에서 위로 올라가며 사라지는 손이에요. 사용자가 스크롤할 때까지 반복해요.
private struct HomeTutorialScrollHint: View {

    enum Phase: CaseIterable {
        case start
        case visible
        case up
        case fade

        var isAtTop: Bool {
            self == .up || self == .fade
        }

        var isVisible: Bool {
            self == .visible || self == .up
        }
    }

    var body: some View {
        Image(.homeTutorialScroll)
            .resizable()
            .frame(width: 84.scaled, height: 124.scaled)
            .phaseAnimator(Phase.allCases) { content, phase in
                content
                    .offset(y: phase.isAtTop ? -60.scaled : 30.scaled)
                    .opacity(phase.isVisible ? 1 : 0)
            } animation: { phase in
                switch phase {
                case .start: .linear(duration: 0.01)
                case .visible: .easeOut(duration: 0.3)
                case .up: .easeInOut(duration: 1)
                case .fade: .easeOut(duration: 0.4)
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - HomeTutorialBouncingLabel

private struct HomeTutorialBouncingLabel: View {

    let text: String

    var body: some View {
        Text(text)
            .plobbyFont(.labelSelected)
            .foregroundStyle(Color(.gray0))
            .fixedSize()
            .phaseAnimator([false, true]) { content, isUp in
                content.offset(y: isUp ? -6.scaled : 0)
            } animation: { _ in
                .easeInOut(duration: 0.6)
            }
            .allowsHitTesting(false)
    }
}

// MARK: - TapArea

/// 화면 전체에서 `hole`만 뺀 영역이에요. 구멍 안의 터치는 아래 화면으로 내려가요.
private struct TapArea: Shape {

    let hole: CGRect?

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        if let hole {
            path.addRect(hole)
        }
        return path
    }
}
