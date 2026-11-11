//
//  PloggingSceneView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct PloggingSceneView: View {

    // MARK: - Properties

    let days: [GoalDailyProgress]
    let stage: HomeSceneStage
    let collectPulse: Int
    /// 해변 위를 걸어간 정도예요. 정수 지점이 각 날짜예요.
    var walkProgress: Double = 0

    // MARK: - Body

    var body: some View {
        HomeSceneCanvas { designHeight in
            let camera = cameraOffset(designHeight: designHeight)

            beach
                .offset(y: -camera)
                .animation(HomeWalkPath.cameraAnimation, value: camera)

            standBack

            // 사람이 먼저 걸어가고 화면이 한 박자 늦게 따라와요.
            Group {
                shadows
                humans
                bags
            }
            .offset(y: walk)
            .animation(HomeWalkPath.walkAnimation, value: walk)
            .offset(y: -camera)
            .animation(HomeWalkPath.cameraAnimation, value: camera)

            standFront
        }
    }
}

// MARK: - Walk Path

extension PloggingSceneView {

    static func walkPath(lastDay: Int) -> HomeWalkPath {
        let days = (0...max(lastDay, 0)).map { Metrics.dayOffset($0, lastDay: lastDay) }
        let finale = Metrics.dayOffset(lastDay, lastDay: lastDay) + Metrics.finaleExtraOffset
        return HomeWalkPath(nodes: [Metrics.beachStartOffset] + days + [finale])
    }
}

// MARK: - Layers

private extension PloggingSceneView {

    var beach: some View {
        ZStack(alignment: .topLeading) {
            Image(.homeSceneBeach)
                .resizable()
                .floatingButtonShadow(Metrics.background)

            ForEach(days.indices, id: \.self) { day in
                ForEach(Metrics.trash[day % Metrics.trash.count]) { item in
                    trash(item, day: day)
                }
            }
        }
        .frame(width: Metrics.background.width, height: Metrics.background.height, alignment: .topLeading)
    }

    var shadows: some View {
        ForEach(Metrics.humans.indices, id: \.self) { index in
            Ellipse()
                .fill(Metrics.sandShadow)
                .floatingButtonShadow(Metrics.shadowRect(for: index).offsetBy(dx: walkOffset.width, dy: walkOffset.height))
                .opacity(isVisible(index) ? 1 : 0)
        }
    }

    var humans: some View {
        ForEach(Metrics.humans.indices, id: \.self) { index in
            ZStack(alignment: .topLeading) {
                Image(Metrics.humans[index].image)
                    .resizable()

                if let bag = Metrics.carriedBagRects[index] {
                    carriedBag(bag, collector: index)
                }
            }
            .frame(width: Metrics.humans[index].rect.width, height: Metrics.humans[index].rect.height, alignment: .topLeading)
            // 쓰레기를 주우면 다 같이 한 명씩 엇갈려 폴짝 뛰어요
            .keyframeAnimator(initialValue: 0.0, trigger: collectPulse) { content, hop in
                content.offset(y: hop)
            } keyframes: { _ in
                LinearKeyframe(0, duration: max(Double(Metrics.visibleOrder.firstIndex(of: index) ?? 0) * 0.06, 0.01))
                SpringKeyframe(-Metrics.jumpHeight, duration: 0.18)
                SpringKeyframe(0, duration: 0.45, spring: .bouncy)
            }
            .floatingButtonShadow(Metrics.humans[index].rect.offsetBy(dx: walkOffset.width, dy: walkOffset.height))
            .offset(y: stepBob(index))
            .opacity(isVisible(index) ? 1 : 0)
        }
    }

    var standBack: some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Color(red: 0x88 / 255, green: 0x67 / 255, blue: 0x46 / 255).opacity(0.14))
                .floatingButtonShadow(CGRect(x: 169, y: 299, width: 84, height: 7))
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0x82 / 255, green: 0x98 / 255, blue: 0x87 / 255))
                .floatingButtonShadow(CGRect(x: 179, y: 283, width: 64, height: 15))
            RoundedRectangle(cornerRadius: 2)
                .fill(Metrics.standDark)
                .floatingButtonShadow(CGRect(x: 171, y: 272, width: 8, height: 30))
            RoundedRectangle(cornerRadius: 2)
                .fill(Metrics.standDark)
                .floatingButtonShadow(CGRect(x: 243, y: 272, width: 8, height: 30))
        }
        .frame(width: HomeSceneCanvas<EmptyView>.designWidth, alignment: .topLeading)
        .opacity(isAtStand ? 1 : 0)
    }

    var standFront: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0x47 / 255, green: 0x64 / 255, blue: 0x59 / 255))
                .floatingButtonShadow(CGRect(x: 171, y: 292, width: 80, height: 10))
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: 0x97 / 255, green: 0xAC / 255, blue: 0x97 / 255))
                .floatingButtonShadow(CGRect(x: 179, y: 292, width: 64, height: 2))
        }
        .frame(width: HomeSceneCanvas<EmptyView>.designWidth, alignment: .topLeading)
        .opacity(isAtStand ? 1 : 0)
    }
}

// MARK: - Bag

private extension PloggingSceneView {

    func carriedBag(_ rect: CGRect, collector: Int) -> some View {
        ZStack(alignment: .topLeading) {
            Image(.homeSceneBag)
                .resizable()
                .scaleEffect(x: -1)

            ForEach(Array(bagTrash(for: collector).enumerated()), id: \.offset) { slot, image in
                let place = Metrics.bagTrashSlots[slot]
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(place.rotation))
                    .floatingButtonShadow(place.rect)
            }
        }
        .frame(width: rect.width, height: rect.height, alignment: .topLeading)
        .rotationEffect(.degrees(stage.isCollected ? Metrics.bagSwingRotation : 0), anchor: Metrics.bagHandleAnchor)
        .floatingButtonShadow(rect)
        .opacity(isAtStand ? 0 : 1)
    }

    var bags: some View {
        ForEach(Metrics.humans.indices, id: \.self) { index in
            Image(.homeSceneBag)
                .resizable()
                .floatingButtonShadow(Metrics.standBagRects[index])
                .opacity(isAtStand ? 1 : 0)
        }
    }
}

// MARK: - Trash

private extension PloggingSceneView {

    func trash(_ item: HomeSceneTrash, day: Int) -> some View {
        let phase = HomeSceneTrashPhase(trashDay: day, stage: stage)
        let rect = phase.isAtCollector
            ? item.rect.homeSceneShrunk(to: Metrics.eatenScale, center: bagMouth(of: collector(for: item, day: day)))
            : item.rect

        return Image(item.image)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(item.rotation))
            .floatingButtonShadow(rect.offsetBy(dx: 0, dy: Metrics.dayOffset(day, lastDay: lastDay)))
            .opacity(phase.opacity)
    }

    func collector(for item: HomeSceneTrash, day: Int) -> Int {
        visibleHumans(on: day).contains(item.collector) ? item.collector : Metrics.defaultCollector
    }

    func bagMouth(of collector: Int) -> CGPoint {
        let human = Metrics.humans[collector].rect
        let bag = Metrics.carriedBagRects[collector] ?? .zero
        return CGPoint(x: human.minX + bag.minX + Metrics.bagMouth.x, y: human.minY + bag.minY + Metrics.bagMouth.y)
    }

    func bagTrash(for collector: Int) -> [ImageResource] {
        let collected = days.indices.flatMap { day in
            Metrics.trash[day % Metrics.trash.count]
                .filter { self.collector(for: $0, day: day) == collector && HomeSceneTrashPhase(trashDay: day, stage: stage) == .collected }
                .map(\.image)
        }
        return Array(collected.suffix(Metrics.bagTrashSlots.count))
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
        isAtStand
            ? Metrics.dayOffset(lastDay, lastDay: lastDay) + Metrics.finaleExtraOffset
            : Metrics.dayOffset(currentDay, lastDay: lastDay)
    }

    /// 사람이 해변 위에서 내려간 거리예요. 마지막 도착점에서는 수거대 앞에 서요.
    var walk: CGFloat {
        isAtStand ? worldOffset : Self.walkPath(lastDay: lastDay).offset(at: walkProgress)
    }

    /// 화면은 사람을 따라 내려가지만 해변 끝을 넘지는 않아요. 그래서 해변 끝에서는 사람이 화면 안에서 걸어가요.
    func cameraOffset(designHeight: CGFloat) -> CGFloat {
        guard !isAtStand else { return worldOffset }
        return min(max(walk, 0), max(Metrics.background.height - designHeight, 0))
    }

    /// 걸을 때 한 걸음마다 살짝 튀어 올라요. 사람마다 발걸음을 엇갈리게 해요.
    func stepBob(_ index: Int) -> CGFloat {
        guard !isAtStand else { return 0 }
        let phase = (walk + CGFloat(index) * Metrics.stepLength / 3) / Metrics.stepLength * .pi
        return -abs(sin(phase)) * Metrics.stepHeight
    }

    var walkOffset: CGSize {
        isAtStand ? Metrics.finaleWalk : .zero
    }

    func isVisible(_ humanIndex: Int) -> Bool {
        visibleHumans(on: currentDay).contains(humanIndex)
    }

    func visibleHumans(on day: Int) -> [Int] {
        guard days.indices.contains(day) else { return [0] }
        let count = min(max(days[day].participantCount, 1), Metrics.humans.count)
        return Array(Metrics.visibleOrder.prefix(count))
    }
}

// MARK: - Metrics

private extension PloggingSceneView {

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

        static let visibleOrder = [1, 3, 5, 4, 0, 2]
        static let sandShadow = Color(red: 0x85 / 255, green: 0x61 / 255, blue: 0x36 / 255).opacity(0.15)
        static let standDark = Color(red: 0x5C / 255, green: 0x77 / 255, blue: 0x6B / 255)

        /// 마지막 날까지 내려가는 거리예요. 이보다 더 내려가면 해변 그림이 끝나요.
        static let lastDayOffset: CGFloat = 500
        /// 날짜가 적을 때 하루에 내려가는 최대 거리예요.
        static let maxDaySpacing: CGFloat = 170
        static let finaleExtraOffset: CGFloat = 52
        static let beachStartOffset: CGFloat = -80
        static let stepLength: CGFloat = 18
        static let stepHeight: CGFloat = 3
        static let jumpHeight: CGFloat = 16
        static let eatenScale: CGFloat = 0.2
        static let finaleWalk = CGSize(width: -16, height: 24)

        static let carriedBagRects: [Int: CGRect] = [
            1: CGRect(x: 5, y: 35, width: 14, height: 23),
            3: CGRect(x: 2, y: 34, width: 14, height: 23)
        ]
        static let defaultCollector = 1
        static let bagMouth = CGPoint(x: 6, y: 9)
        static let bagSwingRotation: Double = -14
        static let bagHandleAnchor = UnitPoint(x: 0.8, y: 0)
        static let bagTrashSlots: [(rect: CGRect, rotation: Double)] = [
            (CGRect(x: 1, y: 7, width: 5, height: 6), -10),
            (CGRect(x: 5.5, y: 5, width: 6, height: 6), 12)
        ]

        static let standBagRects: [CGRect] = [
            CGRect(x: 192, y: 268, width: 14, height: 23),
            CGRect(x: 218, y: 271, width: 14, height: 23),
            CGRect(x: 241, y: 271, width: 14, height: 23),
            CGRect(x: 202, y: 262, width: 14, height: 23),
            CGRect(x: 230, y: 266, width: 14, height: 23),
            CGRect(x: 216, y: 256, width: 14, height: 23)
        ]

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

        /// 날짜 수에 맞춰 해변을 나눠요. 날이 많아도 해변 끝을 넘지 않아요.
        static func dayOffset(_ day: Int, lastDay: Int) -> CGFloat {
            let spacing = min(maxDaySpacing, lastDayOffset / CGFloat(max(lastDay, 1)))
            return CGFloat(min(max(day, 0), lastDay)) * spacing
        }

        static func shadowRect(for humanIndex: Int) -> CGRect {
            let human = humans[humanIndex].rect
            return CGRect(x: human.minX + 6, y: human.minY + 59, width: 25, height: 6)
        }
    }
}
