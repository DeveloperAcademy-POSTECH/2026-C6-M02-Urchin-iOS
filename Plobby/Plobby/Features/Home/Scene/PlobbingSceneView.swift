//
//  PlobbingSceneView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 날짜별로 더 깊이 잠수하며 쓰레기를 줍고, 마지막에 떠올라 배에 싣는 플로빙 장면이에요.
struct PlobbingSceneView: View {

    let days: [HomeGoalDailyProgress]
    let stage: HomeSceneStage
    let collectPulse: Int

    var body: some View {
        HomeSceneCanvas { _ in
            sea
            divers
        }
    }
}

// MARK: - Layers

private extension PlobbingSceneView {

    /// 하늘·수면·배·바닷속·쓰레기는 함께 움직여요. 위로 올라갈수록 깊이 잠수하는 연출이에요.
    var sea: some View {
        ZStack(alignment: .topLeading) {
            Image(.homeSceneSky)
                .resizable()
                .homeScenePlace(Metrics.sky)

            Image(.homeSceneSea)
                .resizable()
                .homeScenePlace(Metrics.seabed)

            Rectangle()
                .fill(Metrics.surfaceLine)
                .homeScenePlace(Metrics.surface)

            Image(.homeSceneBoat)
                .resizable()
                .homeScenePlace(Metrics.boat)

            cargo

            ForEach(days.indices, id: \.self) { day in
                ForEach(Metrics.trash[day % Metrics.trash.count]) { item in
                    trash(item, day: day)
                }
            }
        }
        .frame(width: Metrics.world.width, height: Metrics.world.height, alignment: .topLeading)
        .offset(y: -worldOffset)
    }

    var divers: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Metrics.divers.indices, id: \.self) { index in
                diver(index)
            }
        }
        .frame(width: Metrics.diverGroup.width, height: Metrics.diverGroup.height, alignment: .topLeading)
        // 물속에서 둥실둥실 떠 있어요.
        .phaseAnimator([0.0, 1.0]) { content, phase in
            content.offset(y: phase * 4)
        } animation: { _ in
            .easeInOut(duration: 1.6)
        }
        .scaleEffect(isSurfaced ? Metrics.surfacedScale : 1, anchor: .topLeading)
        .offset(diverOffset)
        .opacity(isLoaded ? 0 : 1)
        .offset(x: Metrics.diverGroup.minX, y: Metrics.diverGroup.minY)
    }

    func diver(_ index: Int) -> some View {
        let spot = Metrics.divers[index]

        return ZStack(alignment: .topLeading) {
            Image(spot.image)
                .resizable()
                .frame(width: 56, height: 31)
                .rotationEffect(.degrees(spot.rotation))
                .position(spot.center)

            Image(.homeSceneNet)
                .resizable()
                .keyframeAnimator(initialValue: 1.0, trigger: collectPulse) { content, scale in
                    content.scaleEffect(scale, anchor: .top)
                } keyframes: { _ in
                    SpringKeyframe(1.3, duration: 0.15)
                    SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
                }
                .rotationEffect(.degrees(8))
                .homeScenePlace(Metrics.netRect(for: index))
        }
        .opacity(isVisible(index) ? 1 : 0)
    }

    func trash(_ item: HomeSceneTrash, day: Int) -> some View {
        let phase = HomeSceneTrashPhase(trashDay: day, stage: stage)
        let arrival = Metrics.arrivalOffset(day)
        let net = Metrics.netRect(for: item.collector).offsetBy(dx: Metrics.diverGroup.minX, dy: Metrics.diverGroup.minY)
        // 줍는 동안 더 잠수하니, 수거망 위치를 그만큼 아래(월드 좌표)로 옮겨 맞춰요.
        let rect = phase.isAtCollector
            ? item.rect.homeSceneShrunk(to: 0.25, center: CGPoint(x: net.midX, y: net.midY + Metrics.collectDive))
            : item.rect

        return Image(item.image)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(item.rotation))
            .homeScenePlace(rect.offsetBy(dx: 0, dy: arrival))
            .opacity(phase.opacity)
    }

    /// 배 갑판에 쌓인 쓰레기예요. 수거 결과 단계에서 올라와요.
    var cargo: some View {
        ForEach(Metrics.cargo.indices, id: \.self) { index in
            let item = Metrics.cargo[index]
            Image(item.image)
                .resizable()
                .scaledToFit()
                .homeScenePlace(item.rect.offsetBy(dx: 0, dy: isLoaded ? 0 : 60))
                .opacity(isLoaded ? 1 : 0)
                .animation(.spring(duration: 0.6, bounce: 0.35).delay(Double(index) * 0.04), value: isLoaded)
        }
    }
}

// MARK: - State

private extension PlobbingSceneView {

    var lastDay: Int { max(days.count - 1, 0) }

    var currentDay: Int { stage.day(lastDay: lastDay) }

    /// 수면으로 올라온 뒤(수면 이동, 수거 결과)예요.
    var isSurfaced: Bool {
        if case let .finale(step) = stage { return step >= 1 }
        return false
    }

    var isLoaded: Bool {
        stage == .finale(step: RecordType.plobbing.resultStep)
    }

    var worldOffset: CGFloat {
        switch stage {
        case let .arrived(day): Metrics.arrivalOffset(day)
        case let .collecting(day), let .collected(day): Metrics.arrivalOffset(day) + Metrics.collectDive
        case .finale(step: 0): Metrics.arrivalOffset(lastDay) + Metrics.collectDive
        case .finale: 0
        }
    }

    var diverOffset: CGSize {
        switch stage {
        case .finale(step: 0): Metrics.swimUpOffset
        case .finale: Metrics.surfacedOffset
        default: .zero
        }
    }

    /// 그날 참여자 수만큼(최대 6명) 다이버를 보여줘요.
    func isVisible(_ diverIndex: Int) -> Bool {
        guard days.indices.contains(currentDay) else { return diverIndex == 0 }
        let count = min(max(days[currentDay].participantCount, 1), Metrics.divers.count)
        return Metrics.visibleOrder.prefix(count).contains(diverIndex)
    }
}

// MARK: - Metrics

private extension PlobbingSceneView {

    /// 피그마 "N월 N일 플로빙 (N단계)" 프레임에서 가져온 좌표예요. (장면 너비 402 기준)
    enum Metrics {

        struct Diver {
            let image: ImageResource
            /// 다이버 그룹 안에서의 중심점이에요.
            let center: CGPoint
            let rotation: Double
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
            Diver(image: .homeDiver01, center: CGPoint(x: 52, y: 39), rotation: 28),
            Diver(image: .homeDiver02, center: CGPoint(x: 112, y: 27), rotation: 32),
            Diver(image: .homeDiver03, center: CGPoint(x: 156, y: 55), rotation: 42),
            Diver(image: .homeDiver04, center: CGPoint(x: 40, y: 87), rotation: 41),
            Diver(image: .homeDiver05, center: CGPoint(x: 100, y: 79), rotation: 34),
            Diver(image: .homeDiver06, center: CGPoint(x: 148, y: 107), rotation: 41)
        ]

        /// 참여자가 적을 때 먼저 보여줄 다이버 순서예요.
        static let visibleOrder = [0, 1, 5, 2, 3, 4]

        /// 날짜마다 얼마나 깊이 내려왔는지예요. 줍는 동안 조금 더 내려가요.
        static let arrivalOffsets: [CGFloat] = [0, 180, 420, 640]
        static let collectDive: CGFloat = 55

        /// 마지막 날 수거 후 위쪽으로 헤엄쳐 올라가요.
        static let swimUpOffset = CGSize(width: 16, height: -56)
        /// 수면 근처로 떠오르며 작아져요.
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

        static func arrivalOffset(_ day: Int) -> CGFloat {
            arrivalOffsets[min(day, arrivalOffsets.count - 1)]
        }

        /// 다이버가 들고 있는 수거망이에요. (다이버 그룹 좌표)
        static func netRect(for diverIndex: Int) -> CGRect {
            let center = divers[diverIndex].center
            return CGRect(x: center.x + 14, y: center.y + 18, width: 16, height: 19)
        }
    }
}
