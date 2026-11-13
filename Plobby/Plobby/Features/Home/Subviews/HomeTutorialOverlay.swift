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
    case activitySwitch
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
        case .activitySwitch: nil
        case .finish: nil
        }
    }

    /// 하루치 기록을 담은 뒤부터 날짜 옆에 개수 칩이 보여요.
    var showsCountChip: Bool {
        switch self {
        case .recordResult, .activitySwitch, .finish: true
        default: false
        }
    }

    /// 기록 결과부터는 오른쪽 아래 전환 버튼과 "플로빙 보기" 라벨을 함께 보여줘요.
    var showsActivityToggle: Bool {
        self == .recordResult || self == .activitySwitch
    }

    var target: HomeTutorialTarget? {
        switch self {
        case .goal, .goalToggle, .goalFill, .goalPeriod: .goalCard
        case .recordIntro, .recordResult, .scroll: .scene
        case .activitySwitch: .activityToggle
        case .finish: nil
        }
    }
}

enum HomeTutorialTarget: Hashable {
    case goalCard
    case activityToggle
    /// 장면 위의 날짜 칩과 개수 칩이에요. 장면을 비추는 단계에서 함께 밝게 보여줘요.
    case dayChip
    case countChip
    case scene
}

// MARK: - HomeTutorialOverlay

/// 홈 위를 어둡게 덮고 단계마다 한 곳만 밝게 비춰요. 아무 곳이나 누르면 다음 단계로 넘어가요.
struct HomeTutorialOverlay: View {

    // MARK: - Properties

    let step: HomeTutorialStep
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
                        activityToggle: step.target == .activityToggle ? nil : activityToggle
                    )

                    if let message = step.message {
                        // 문구가 바뀌면 이전 문구는 흐려지며 사라지고 새 문구가 나타나요.
                        caption(message, highlight: highlight, dayChip: dayChip)
                            .id(message)
                            .transition(.opacity)
                    }

                    if step == .scroll {
                        HomeTutorialScrollHint()
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    }

                    if let activityToggle {
                        // 버튼과 가로 가운데를 맞추고, 버튼 위쪽에서 24 떨어진 곳에 라벨 아래쪽이 오도록 놓아요.
                        HomeTutorialBouncingLabel(text: "\(RecordType.plobbing.name) 보기")
                            .position(
                                x: activityToggle.midX,
                                y: activityToggle.minY - 24.scaled - PlobbyTypography.labelSelected.lineHeight.scaled / 2
                            )
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            // 펼치기 안내에서는 강조한 목표 카드만 눌리게 비워 두고, 나머지 영역은 눌러도 넘어가지 않아요.
            .contentShape(TapArea(hole: step == .goalToggle ? highlight : nil), eoFill: true)
            .onTapGesture {
                guard ![.goalToggle, .goalFill, .scroll, .finish].contains(step) else { return }
                onAdvance()
            }
            // 스크롤 안내는 실제로 위로 쓸어 올려야 넘어가요.
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

    /// 장면을 비추는 단계에서는 날짜 칩과 공통 목표 카드도 함께 밝게 둬요.
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
                .position(Self.spotlightCenter(in: rect))

        case .activityToggle:
            let diameter = max(rect.width, rect.height) + 8.scaled

            Circle()
                .frame(width: diameter, height: diameter)
                .position(x: rect.midX, y: rect.midY)

        default:
            let padding = 4.scaled
            let padded = rect.insetBy(dx: -padding, dy: -padding)

            RoundedRectangle(cornerRadius: 16.scaled)
                .frame(width: padded.width, height: padded.height)
                .position(x: padded.midX, y: padded.midY)
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

    // ponytail: 장면 속 사람들 위치를 장면 크기 비율로 어림잡았어요. 장면 배치가 바뀌면 이 비율을 조정해요.
    static func spotlightCenter(in scene: CGRect) -> CGPoint {
        CGPoint(x: scene.minX + scene.width * 0.68, y: scene.minY + scene.height * 0.42)
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

    /// 아래에서 나타나 → 위로 올라가고 → 위에 닿으면 사라진 뒤 → 다시 아래로 돌아가요.
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

/// 위아래로 천천히 오가며 눈길을 끄는 라벨이에요.
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
