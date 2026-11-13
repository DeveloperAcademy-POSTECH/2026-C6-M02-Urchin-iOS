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
    case goalPeriod
    case recordIntro
    case recordResult
    case scroll
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
        case .goalPeriod: "기간이 끝나거나 목표가 달성되면 새 목표가 시작돼요"
        case .recordIntro: "기록이 쌓이면 어떻게 보일까요?"
        case .recordResult: "이렇게 기록하면 공통 목표에 포함돼요"
        case .scroll: "스크롤해 보세요"
        case .activitySwitch: "플로빙 기록도 볼 수 있어요"
        case .finish: nil
        }
    }

    var target: HomeTutorialTarget? {
        switch self {
        case .goal, .goalToggle, .goalPeriod: .goalCard
        case .recordIntro, .recordResult, .scroll: .scene
        case .activitySwitch: .activityTabs
        case .finish: nil
        }
    }
}

enum HomeTutorialTarget: Hashable {
    case goalCard
    case activityTabs
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

            ZStack(alignment: .top) {
                if step == .finish {
                    finishView
                } else {
                    dimmedBackground(highlight: highlight)

                    if let message = step.message {
                        // 문구가 바뀌면 이전 문구는 흐려지며 사라지고 새 문구가 나타나요.
                        caption(message, highlight: highlight)
                            .id(message)
                            .transition(.opacity)
                    }

                    if step == .scroll, let highlight {
                        HomeTutorialHand()
                            .position(Self.spotlightCenter(in: highlight))
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            // 펼치기 안내에서는 강조한 목표 카드만 눌리게 비워 두고, 나머지 영역은 눌러도 넘어가지 않아요.
            .contentShape(TapArea(hole: step == .goalToggle ? highlight : nil), eoFill: true)
            .onTapGesture {
                guard step != .finish, step != .goalToggle else { return }
                onAdvance()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 어두운 막

private extension HomeTutorialOverlay {

    func dimmedBackground(highlight: CGRect?) -> some View {
        Color(.neutralBlack)
            .opacity(0.6)
            .mask {
                ZStack {
                    Rectangle()

                    if let highlight {
                        hole(highlight)
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
            }
    }

    @ViewBuilder
    func hole(_ rect: CGRect) -> some View {
        if step.target == .scene {
            let diameter = Self.spotlightDiameter.scaled

            Circle()
                .frame(width: diameter, height: diameter)
                .blur(radius: 24)
                .position(Self.spotlightCenter(in: rect))
        } else {
            let padding = 4.scaled
            let padded = rect.insetBy(dx: -padding, dy: -padding)

            RoundedRectangle(cornerRadius: 16.scaled)
                .frame(width: padded.width, height: padded.height)
                .position(x: padded.midX, y: padded.midY)
        }
    }

    func caption(_ message: String, highlight: CGRect?) -> some View {
        Text(message)
            .plobbyFont(.actionLabel)
            .foregroundStyle(Color(.gray0))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24.scaled)
            .padding(.top, captionTop(highlight: highlight))
    }

    func captionTop(highlight: CGRect?) -> CGFloat {
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

// MARK: - HomeTutorialHand

/// 아래에서 위로 올라가며 사라지는 손가락이에요. 스크롤 방향을 보여줘요.
private struct HomeTutorialHand: View {

    enum Phase: CaseIterable {
        case start
        case visible
        case up
    }

    var body: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 40.scaled))
            .foregroundStyle(Color(.gray0))
            .phaseAnimator(Phase.allCases) { content, phase in
                content
                    .offset(y: phase == .up ? -60.scaled : 30.scaled)
                    .opacity(phase == .visible ? 1 : 0)
            } animation: { phase in
                switch phase {
                case .start: .linear(duration: 0.2)
                case .visible: .easeOut(duration: 0.3)
                case .up: .easeInOut(duration: 1)
                }
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
