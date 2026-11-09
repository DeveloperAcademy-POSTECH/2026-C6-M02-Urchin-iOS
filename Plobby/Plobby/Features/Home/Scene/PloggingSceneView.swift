//
//  PloggingSceneView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 해변을 따라 내려가며 날짜별로 쓰레기를 줍고, 마지막에 수거대에 모으는 플로깅 장면이에요.
struct PloggingSceneView: View {

    let days: [HomeGoalDailyProgress]
    let stage: HomeSceneStage
    let collectPulse: Int

    var body: some View {
        HomeSceneCanvas { _ in
            beach
            standBack
            shadows
            humans
            bags
            standFront
        }
    }
}

// MARK: - Layers

private extension PloggingSceneView {

    /// 배경과 쓰레기는 함께 스크롤돼요. 사람은 화면에 머물고 해변이 지나가요.
    var beach: some View {
        ZStack(alignment: .topLeading) {
            Image(.homeSceneBeach)
                .resizable()
                .homeScenePlace(Metrics.background)

            ForEach(days.indices, id: \.self) { day in
                ForEach(Metrics.trash[day % Metrics.trash.count]) { item in
                    trash(item, day: day)
                }
            }
        }
        .frame(width: Metrics.background.width, height: Metrics.background.height, alignment: .topLeading)
        .offset(y: -worldOffset)
    }

    var shadows: some View {
        ForEach(Metrics.humans.indices, id: \.self) { index in
            Ellipse()
                .fill(Metrics.sandShadow)
                .homeScenePlace(Metrics.shadowRect(for: index).offsetBy(dx: walkOffset.width, dy: walkOffset.height))
                .opacity(isVisible(index) ? 1 : 0)
        }
    }

    /// 쓰레기를 주운 사람은 수거가 끝날 때 살짝 뛰어올라요.
    var humans: some View {
        ForEach(Metrics.humans.indices, id: \.self) { index in
            Image(Metrics.humans[index].image)
                .resizable()
                .keyframeAnimator(initialValue: 0.0, trigger: collectPulse) { content, hop in
                    content.offset(y: Metrics.collectors.contains(index) ? hop : 0)
                } keyframes: { _ in
                    SpringKeyframe(-6, duration: 0.15)
                    SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                }
                .homeScenePlace(Metrics.humans[index].rect.offsetBy(dx: walkOffset.width, dy: walkOffset.height))
                .opacity(isVisible(index) ? 1 : 0)
        }
    }

    /// 봉투를 든 사람이 쓰레기를 담고, 마지막에는 봉투가 모두 수거대에 모여요.
    var bags: some View {
        ForEach(Metrics.humans.indices, id: \.self) { index in
            Image(.homeSceneBag)
                .resizable()
                .homeScenePlace(bagRect(for: index))
                .opacity(isAtStand || (Metrics.collectors.contains(index) && isVisible(index)) ? 1 : 0)
        }
    }

    /// 수거대 뒤판이에요. 봉투보다 뒤에 그려요.
    var standBack: some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Color(red: 0x88 / 255, green: 0x67 / 255, blue: 0x46 / 255).opacity(0.14))
                .homeScenePlace(CGRect(x: 169, y: 299, width: 84, height: 7))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0x82 / 255, green: 0x98 / 255, blue: 0x87 / 255))
                .homeScenePlace(CGRect(x: 179, y: 283, width: 64, height: 15))
            RoundedRectangle(cornerRadius: 2)
                .fill(Metrics.standDark)
                .homeScenePlace(CGRect(x: 171, y: 272, width: 8, height: 30))
            RoundedRectangle(cornerRadius: 2)
                .fill(Metrics.standDark)
                .homeScenePlace(CGRect(x: 243, y: 272, width: 8, height: 30))
        }
        .frame(width: HomeSceneCanvas<EmptyView>.designWidth, alignment: .topLeading)
        .opacity(isAtStand ? 1 : 0)
    }

    /// 수거대 앞턱이에요. 봉투를 살짝 가려요.
    var standFront: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0x47 / 255, green: 0x64 / 255, blue: 0x59 / 255))
                .homeScenePlace(CGRect(x: 171, y: 292, width: 80, height: 10))
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 0x97 / 255, green: 0xAC / 255, blue: 0x97 / 255))
                .homeScenePlace(CGRect(x: 179, y: 292, width: 64, height: 2))
        }
        .frame(width: HomeSceneCanvas<EmptyView>.designWidth, alignment: .topLeading)
        .opacity(isAtStand ? 1 : 0)
    }

    func trash(_ item: HomeSceneTrash, day: Int) -> some View {
        let phase = HomeSceneTrashPhase(trashDay: day, stage: stage)
        let bag = Metrics.bagRect(for: item.collector)
        let rect = phase.isAtCollector
            ? item.rect.homeSceneShrunk(to: 0.25, center: CGPoint(x: bag.midX, y: bag.minY + 6))
            : item.rect

        return Image(item.image)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(item.rotation))
            .homeScenePlace(rect.offsetBy(dx: 0, dy: Metrics.dayOffset(day)))
            .opacity(phase.opacity)
    }
}

// MARK: - State

private extension PloggingSceneView {

    var lastDay: Int { max(days.count - 1, 0) }

    var currentDay: Int { stage.day(lastDay: lastDay) }

    var isAtStand: Bool {
        if case .finale = stage { return true }
        return false
    }

    var worldOffset: CGFloat {
        isAtStand ? Metrics.dayOffset(lastDay) + Metrics.finaleExtraOffset : Metrics.dayOffset(currentDay)
    }

    /// 마지막에는 모두 함께 수거대 쪽으로 걸어 내려가요.
    var walkOffset: CGSize {
        isAtStand ? Metrics.finaleWalk : .zero
    }

    func bagRect(for humanIndex: Int) -> CGRect {
        isAtStand ? Metrics.standBagRects[humanIndex] : Metrics.bagRect(for: humanIndex)
    }

    /// 그날 참여자 수만큼(최대 6명) 사람을 보여줘요.
    func isVisible(_ humanIndex: Int) -> Bool {
        guard days.indices.contains(currentDay) else { return humanIndex == 0 }
        let count = min(max(days[currentDay].participantCount, 1), Metrics.humans.count)
        return Metrics.visibleOrder.prefix(count).contains(humanIndex)
    }
}

// MARK: - Metrics

private extension PloggingSceneView {

    /// 피그마 "N월 N일 플로깅 (N단계)" 프레임에서 가져온 좌표예요. (장면 너비 402 기준)
    enum Metrics {

        struct Human {
            let image: ImageResource
            let rect: CGRect
        }

        static let background = CGRect(x: 0, y: 0, width: 402, height: 1200)

        static let humans: [Human] = [
            Human(image: .homeHuman01, rect: CGRect(x: 206, y: 112, width: 37, height: 64)),
            Human(image: .homeHuman02, rect: CGRect(x: 258, y: 88, width: 40, height: 64)),
            Human(image: .homeHuman03, rect: CGRect(x: 318, y: 110, width: 37, height: 64)),
            Human(image: .homeHuman04, rect: CGRect(x: 281, y: 166, width: 42, height: 63)),
            Human(image: .homeHuman05, rect: CGRect(x: 226, y: 177, width: 38, height: 64)),
            Human(image: .homeHuman06, rect: CGRect(x: 334, y: 176, width: 28, height: 64))
        ]

        /// 참여자가 적을 때 먼저 보여줄 사람 순서예요. 봉투를 든 사람(2, 4번)이 먼저 나와요.
        static let visibleOrder = [1, 3, 5, 4, 0, 2]
        /// 봉투를 들고 쓰레기를 담는 사람이에요.
        static let collectors: Set<Int> = [1, 3]

        static let sandShadow = Color(red: 0x85 / 255, green: 0x61 / 255, blue: 0x36 / 255).opacity(0.15)
        static let standDark = Color(red: 0x5C / 255, green: 0x77 / 255, blue: 0x6B / 255)

        /// 날짜마다 해변을 얼마나 내려왔는지예요. 날짜가 더 많으면 끝 위치에 머물러요.
        static let dayOffsets: [CGFloat] = [0, 130, 252, 500]
        static let finaleExtraOffset: CGFloat = 52
        static let finaleWalk = CGSize(width: -16, height: 24)

        /// 수거대 안에 놓이는 봉투 위치예요.
        static let standBagRects: [CGRect] = [
            CGRect(x: 192, y: 268, width: 14, height: 23),
            CGRect(x: 218, y: 271, width: 14, height: 23),
            CGRect(x: 241, y: 271, width: 14, height: 23),
            CGRect(x: 202, y: 262, width: 14, height: 23),
            CGRect(x: 230, y: 266, width: 14, height: 23),
            CGRect(x: 216, y: 256, width: 14, height: 23)
        ]

        /// 날짜별로 흩어진 쓰레기예요. 기록한 날이 4일보다 많으면 같은 배치를 순서대로 다시 써요.
        static let trash: [[HomeSceneTrash]] = [
            [
                HomeSceneTrash(image: .sodaCanMintS, rect: CGRect(x: 375, y: 227, width: 13, height: 19), collector: 3),
                HomeSceneTrash(image: .buoyHorizontalOrangeS, rect: CGRect(x: 259, y: 274, width: 34, height: 17), collector: 1),
                HomeSceneTrash(image: .bottleWhiteS, rect: CGRect(x: 192, y: 300, width: 11, height: 27), collector: 1)
            ],
            [
                HomeSceneTrash(image: .cupRedS, rect: CGRect(x: 300, y: 240, width: 20, height: 28), collector: 3),
                HomeSceneTrash(image: .tubeYellowS, rect: CGRect(x: 209, y: 256, width: 12, height: 26), collector: 1),
                HomeSceneTrash(image: .glassBottleGreenS, rect: CGRect(x: 352, y: 300, width: 9, height: 30), collector: 1)
            ],
            [
                HomeSceneTrash(image: .tinCanRedS, rect: CGRect(x: 250, y: 262, width: 18, height: 14), collector: 3),
                HomeSceneTrash(image: .bottleBlueS, rect: CGRect(x: 352, y: 236, width: 10, height: 24), collector: 1),
                HomeSceneTrash(image: .plasticBagWhiteS, rect: CGRect(x: 200, y: 300, width: 16, height: 22), collector: 1)
            ],
            [
                HomeSceneTrash(image: .tubeYellowS, rect: CGRect(x: 235, y: 268, width: 12, height: 26), collector: 1),
                HomeSceneTrash(image: .cupRedS, rect: CGRect(x: 330, y: 290, width: 20, height: 28), collector: 3),
                HomeSceneTrash(image: .buoyHorizontalOrangeS, rect: CGRect(x: 186, y: 320, width: 36, height: 18), collector: 1)
            ]
        ]

        static func dayOffset(_ day: Int) -> CGFloat {
            dayOffsets[min(day, dayOffsets.count - 1)]
        }

        static func shadowRect(for humanIndex: Int) -> CGRect {
            let human = humans[humanIndex].rect
            return CGRect(x: human.minX + 6, y: human.minY + 59, width: 25, height: 6)
        }

        static func bagRect(for humanIndex: Int) -> CGRect {
            let human = humans[humanIndex].rect
            return CGRect(x: human.minX + 15, y: human.minY + 35, width: 14, height: 23)
        }
    }
}
