//
//  PlobbingSceneView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct PlobbingSceneView: View {

    // MARK: - Properties

    let days: [GoalDailyProgress]
    let stage: HomeSceneStage
    let collectPulse: Int
    /// 바닷속을 헤엄쳐 간 정도예요. 정수 지점이 각 날짜예요.
    var walkProgress: Double = 0

    // MARK: - Body

    var body: some View {
        HomeSceneCanvas { designHeight in
            let camera = cameraOffset(designHeight: designHeight)

            sea
                .offset(y: -camera)
                .animation(HomeWalkPath.cameraAnimation, value: camera)

            // 다이버가 먼저 헤엄쳐 가고 화면이 한 박자 늦게 따라와요.
            divers
                .offset(y: walk)
                .animation(HomeWalkPath.walkAnimation, value: walk)
                .offset(y: -camera)
                .animation(HomeWalkPath.cameraAnimation, value: camera)
        }
    }
}

// MARK: - Walk Path

extension PlobbingSceneView {

    /// 쓰레기를 주운 날은 그만큼 더 깊이 들어가 있어요.
    static func walkPath(lastDay: Int, stage: HomeSceneStage) -> HomeWalkPath {
        let collectedThrough = stage.collectedThrough(lastDay: lastDay)
        let days = (0...max(lastDay, 0)).map { day in
            Metrics.arrivalOffset(day, lastDay: lastDay) + (day <= collectedThrough ? Metrics.collectDive : 0)
        }
        let finale = Metrics.arrivalOffset(lastDay, lastDay: lastDay) + Metrics.collectDive
        return HomeWalkPath(nodes: [Metrics.seaStartOffset] + days + [finale])
    }
}

// MARK: - Layers

private extension PlobbingSceneView {

    var sea: some View {
        ZStack(alignment: .topLeading) {
            Image(.homeSceneSky)
                .resizable()
                .floatingButtonShadow(Metrics.sky)

            Image(.homeSceneSea)
                .resizable()
                .floatingButtonShadow(Metrics.seabed)

            Rectangle()
                .fill(Metrics.surfaceLine)
                .floatingButtonShadow(Metrics.surface)

            Image(.homeSceneBoat)
                .resizable()
                .floatingButtonShadow(Metrics.boat)

            cargo

            ForEach(days.indices, id: \.self) { day in
                ForEach(Metrics.trash[day % Metrics.trash.count]) { item in
                    trash(item, day: day)
                }
            }
        }
        .frame(width: Metrics.world.width, height: Metrics.world.height, alignment: .topLeading)
    }

    var divers: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Metrics.divers.indices, id: \.self) { index in
                diver(index)
            }
        }
        .frame(width: Metrics.diverGroup.width, height: Metrics.diverGroup.height, alignment: .topLeading)
        .phaseAnimator([0.0, 1.0]) { content, phase in
            content.offset(y: phase * 4)
        } animation: { _ in
            .easeInOut(duration: 1.6)
        }
        .rotationEffect(.degrees(swimSway * Metrics.swayRotation), anchor: .center)
        .offset(x: swimSway * Metrics.swayWidth)
        .scaleEffect(isSurfaced ? Metrics.surfacedScale : 1, anchor: .topLeading)
        .offset(diverOffset)
        .opacity(isLoaded ? 0 : 1)
        .offset(x: Metrics.diverGroup.minX, y: Metrics.diverGroup.minY)
    }

    func diver(_ index: Int) -> some View {
        let spot = Metrics.divers[index]
        let netAnchor = spot.netAnchor

        return ZStack(alignment: .topLeading) {
            Image(spot.image)
                .resizable()

            ForEach(Array(netTrash(for: index).enumerated()), id: \.offset) { slot, image in
                let place = Metrics.netTrashSlots[slot]
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(place.rotation))
                    .floatingButtonShadow(CGRect(
                        x: spot.netCenter.x + place.offset.x - Metrics.netTrashSize.width / 2,
                        y: spot.netCenter.y + place.offset.y - Metrics.netTrashSize.height / 2,
                        width: Metrics.netTrashSize.width,
                        height: Metrics.netTrashSize.height
                    ))
            }
        }
        .frame(width: spot.rect.width, height: spot.rect.height, alignment: .topLeading)
        .keyframeAnimator(initialValue: 1.0, trigger: collectPulse) { content, scale in
            content.scaleEffect(scale, anchor: netAnchor)
        } keyframes: { _ in
            SpringKeyframe(1.08, duration: 0.15)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        }
        .floatingButtonShadow(spot.rect)
        .opacity(isVisible(index) ? 1 : 0)
    }

    var cargo: some View {
        ForEach(Metrics.cargo.indices, id: \.self) { index in
            let item = Metrics.cargo[index]
            Image(item.image)
                .resizable()
                .scaledToFit()
                .floatingButtonShadow(item.rect.offsetBy(dx: 0, dy: isLoaded ? 0 : 60))
                .opacity(isLoaded ? 1 : 0)
                .animation(.spring(duration: 0.6, bounce: 0.35).delay(Double(index) * 0.04), value: isLoaded)
        }
    }
}

// MARK: - Trash

private extension PlobbingSceneView {

    func netTrash(for diverIndex: Int) -> [ImageResource] {
        let collected = days.indices.flatMap { day in
            Metrics.trash[day % Metrics.trash.count]
                .filter { $0.collector == diverIndex && HomeSceneTrashPhase(trashDay: day, stage: stage) == .collected }
                .map(\.image)
        }
        return Array(collected.suffix(Metrics.netTrashSlots.count))
    }

    func trash(_ item: HomeSceneTrash, day: Int) -> some View {
        let phase = HomeSceneTrashPhase(trashDay: day, stage: stage)
        let arrival = Metrics.arrivalOffset(day, lastDay: lastDay)
        let net = Metrics.netRect(for: item.collector).offsetBy(dx: Metrics.diverGroup.minX, dy: Metrics.diverGroup.minY)
        let rect = phase.isAtCollector
            ? item.rect.homeSceneShrunk(to: 0.25, center: CGPoint(x: net.midX, y: net.midY + Metrics.collectDive))
            : item.rect

        return Image(item.image)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(item.rotation))
            .floatingButtonShadow(rect.offsetBy(dx: 0, dy: arrival))
            .opacity(phase.opacity)
    }
}

// MARK: - State

private extension PlobbingSceneView {

    var lastDay: Int { max(days.count - 1, 0) }

    var currentDay: Int { stage.day(lastDay: lastDay) }

    var isSurfaced: Bool {
        if case let .finale(step) = stage { return step >= 1 }
        return false
    }

    var isLoaded: Bool {
        stage == .finale(step: RecordType.plobbing.resultStep)
    }

    var worldOffset: CGFloat {
        switch stage {
        case let .arrived(day): Metrics.arrivalOffset(day, lastDay: lastDay)
        case let .collecting(day), let .collected(day):
            Metrics.arrivalOffset(day, lastDay: lastDay) + Metrics.collectDive
        case .finale(step: 0): Metrics.arrivalOffset(lastDay, lastDay: lastDay) + Metrics.collectDive
        case .finale: 0
        }
    }

    /// 다이버가 바닷속에서 내려간 거리예요. 마지막 도착점에서는 배로 올라가요.
    var walk: CGFloat {
        if case .finale = stage { return worldOffset }
        return Self.walkPath(lastDay: lastDay, stage: stage).offset(at: walkProgress)
    }

    /// 화면은 다이버를 따라 내려가지만 바다 끝을 넘지는 않아요. 그래서 바다 끝에서는 다이버가 화면 안에서 헤엄쳐요.
    func cameraOffset(designHeight: CGFloat) -> CGFloat {
        if case .finale = stage { return worldOffset }
        return min(max(walk, 0), max(Metrics.world.height - designHeight, 0))
    }

    /// 헤엄칠 때 좌우로 살랑살랑 흔들려요. -1...1이에요.
    var swimSway: CGFloat {
        if case .finale = stage { return 0 }
        return sin(walk / Metrics.strokeLength * .pi)
    }

    var diverOffset: CGSize {
        switch stage {
        case .finale(step: 0): Metrics.swimUpOffset
        case .finale: Metrics.surfacedOffset
        default: .zero
        }
    }

    func isVisible(_ diverIndex: Int) -> Bool {
        guard days.indices.contains(currentDay) else { return diverIndex == 0 }
        let count = min(max(days[currentDay].participantCount, 1), Metrics.divers.count)
        return Metrics.visibleOrder.prefix(count).contains(diverIndex)
    }
}

// MARK: - Metrics

private extension PlobbingSceneView {

    enum Metrics {

        struct Diver {
            let image: ImageResource
            let rect: CGRect
            let netCenter: CGPoint

            var netAnchor: UnitPoint {
                UnitPoint(x: netCenter.x / rect.width, y: netCenter.y / rect.height)
            }
        }

        struct Cargo {
            let image: ImageResource
            let rect: CGRect
        }

        static let world = CGRect(x: 0, y: 0, width: 402, height: 1332)
        static let sky = CGRect(x: 0, y: 0, width: 402, height: 132)
        static let surface = CGRect(x: 0, y: 130, width: 402, height: 2)
        static let seabed = CGRect(x: 0, y: 132, width: 402, height: 1200)
        static let boat = CGRect(x: 112, y: 44, width: 179, height: 99)
        static let surfaceLine = Color(red: 0xC2 / 255, green: 0xE6 / 255, blue: 0xF0 / 255)

        static let diverGroup = CGRect(x: 90, y: 172, width: 190, height: 152)
        static let divers: [Diver] = [
            Diver(image: .homeDiver01, rect: CGRect(x: 19.46, y: 12, width: 76, height: 66), netCenter: CGPoint(x: 56.02, y: 53.3)),
            Diver(image: .homeDiver02, rect: CGRect(x: 77.04, y: 0, width: 76, height: 68), netCenter: CGPoint(x: 53.44, y: 52.3)),
            Diver(image: .homeDiver03, rect: CGRect(x: 120.92, y: 28, width: 65, height: 73), netCenter: CGPoint(x: 47.56, y: 62.3)),
            Diver(image: .homeDiver04, rect: CGRect(x: 0, y: 60, width: 75, height: 73), netCenter: CGPoint(x: 52.48, y: 60.3)),
            Diver(image: .homeDiver05, rect: CGRect(x: 63.87, y: 52, width: 76, height: 69), netCenter: CGPoint(x: 54.61, y: 57.3)),
            Diver(image: .homeDiver06, rect: CGRect(x: 108, y: 80, width: 75, height: 75), netCenter: CGPoint(x: 54.48, y: 64.3))
        ]

        static let visibleOrder = [0, 1, 5, 2, 3, 4]

        static let netTrashSize = CGSize(width: 7, height: 8)
        static let netTrashSlots: [(offset: CGPoint, rotation: Double)] = [
            (CGPoint(x: -2.5, y: 2.5), 24),
            (CGPoint(x: 2.5, y: 0.5), -12)
        ]
        /// 마지막 날까지 내려가는 깊이예요. 이보다 더 내려가면 바다 그림이 끝나요.
        static let lastArrivalOffset: CGFloat = 640
        /// 날짜가 적을 때 하루에 내려가는 최대 깊이예요.
        static let maxDaySpacing: CGFloat = 220
        static let collectDive: CGFloat = 55
        static let seaStartOffset: CGFloat = -30
        static let strokeLength: CGFloat = 60
        static let swayWidth: CGFloat = 8
        static let swayRotation: Double = 3
        static let swimUpOffset = CGSize(width: 16, height: -56)
        static let surfacedScale: CGFloat = 0.6
        static let surfacedOffset = CGSize(width: 18, height: -66)
        
        static let trash: [[HomeSceneTrash]] = [
            [
                HomeSceneTrash(image: .bottleWhiteS, rect: CGRect(x: 109, y: 300, width: 14, height: 34), collector: 0, rotation: -24),
                HomeSceneTrash(image: .buoyHorizontalOrangeS, rect: CGRect(x: 262, y: 330, width: 36, height: 19), collector: 1, rotation: -12),
                HomeSceneTrash(image: .sodaCanMintS, rect: CGRect(x: 140, y: 400, width: 18, height: 26), collector: 5)
            ],
            [
                HomeSceneTrash(image: .plasticBagWhiteS, rect: CGRect(x: 280, y: 330, width: 22, height: 30), collector: 1, rotation: 12),
                HomeSceneTrash(image: .glassBottleGreenS, rect: CGRect(x: 140, y: 350, width: 10, height: 34), collector: 0, rotation: 24),
                HomeSceneTrash(image: .tinCanRedS, rect: CGRect(x: 240, y: 410, width: 24, height: 19), collector: 5, rotation: -24)
            ],
            [
                HomeSceneTrash(image: .sodaCanMintS, rect: CGRect(x: 110, y: 340, width: 18, height: 26), collector: 3),
                HomeSceneTrash(image: .bottleBlueS, rect: CGRect(x: 305, y: 300, width: 14, height: 34), collector: 2, rotation: 12),
                HomeSceneTrash(image: .buoyHorizontalOrangeS, rect: CGRect(x: 200, y: 410, width: 36, height: 19), collector: 4, rotation: -12)
            ],
            [
                HomeSceneTrash(image: .bottleWhiteS, rect: CGRect(x: 125, y: 330, width: 14, height: 34), collector: 0, rotation: 24),
                HomeSceneTrash(image: .cupRedS, rect: CGRect(x: 265, y: 390, width: 18, height: 25), collector: 3, rotation: -12),
                HomeSceneTrash(image: .plasticBagWhiteS, rect: CGRect(x: 310, y: 290, width: 22, height: 30), collector: 5)
            ]
        ]

        static let cargo: [Cargo] = [
            Cargo(image: .bottleWhiteS, rect: CGRect(x: 127, y: 70, width: 8, height: 18)),
            Cargo(image: .buoyHorizontalOrangeS, rect: CGRect(x: 138, y: 78, width: 18, height: 10)),
            Cargo(image: .sodaCanMintS, rect: CGRect(x: 158, y: 74, width: 10, height: 14)),
            Cargo(image: .glassBottleGreenS, rect: CGRect(x: 171, y: 69, width: 6, height: 19)),
            Cargo(image: .tinCanRedS, rect: CGRect(x: 180, y: 78, width: 13, height: 10)),
            Cargo(image: .plasticBagWhiteS, rect: CGRect(x: 145, y: 64, width: 11, height: 15)),
            Cargo(image: .cupRedS, rect: CGRect(x: 196, y: 75, width: 9, height: 13))
        ]

        /// 날짜 수에 맞춰 바다를 나눠요. 날이 많아도 바다 끝을 넘지 않아요.
        static func arrivalOffset(_ day: Int, lastDay: Int) -> CGFloat {
            let spacing = min(maxDaySpacing, lastArrivalOffset / CGFloat(max(lastDay, 1)))
            return CGFloat(min(max(day, 0), lastDay)) * spacing
        }

        static func netRect(for diverIndex: Int) -> CGRect {
            let diver = divers[diverIndex]
            return CGRect(
                x: diver.rect.minX + diver.netCenter.x - 8,
                y: diver.rect.minY + diver.netCenter.y - 9.5,
                width: 16,
                height: 19
            )
        }
    }
}
