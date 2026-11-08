//
//  CollectionCardView.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import SpriteKit
import SwiftUI

import ComposableArchitecture

struct CollectionCardView: View {

    // MARK: - Properties

    let store: StoreOf<CollectionCardFeature>

    // MARK: - Body

    var body: some View {
        FlipCard(
            angle: store.isFlipped ? 180 : 0,
            front: front,
            back: back
        )
        .animation(.easeInOut(duration: 0.6), value: store.isFlipped)
    }
}

// MARK: - 카드 앞면

private extension CollectionCardView {

    var front: some View {
        VStack(spacing: 0) {
            header
            trashPile
            collectedCount
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.gray900), in: RoundedRectangle(cornerRadius: 20.scaled))
    }

    var header: some View {
        HStack(spacing: 0) {
            Text("플라스틱")    // TODO: - 수정 예정
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.gray0))
                .padding(.leading, 8.scaled)

            Spacer()

            flipButton
        }
        .padding(.top, 16.scaled)
        .padding(.horizontal, 16.scaled)
    }

    var flipButton: some View {
        Button {
            store.send(.flipButtonTapped)
        } label: {
            Image(.collectionCardFlip)
                .resizable()
                .frame(width: 23.scaled, height: 23.scaled)
                .frame(width: 42.scaled, height: 42.scaled)
                .foregroundStyle(Color(.gray0))
                .background(Color(.gray900), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.currentNeutralGray), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    var trashPile: some View {
        TrashPileView(
            category: store.selectedCategory,
            count: store.collectedCount
        )
        .id(store.selectedCategory)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16.scaled)
        .padding(.bottom, 8.scaled)
    }

    var collectedCount: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("지금까지 모은 개수")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.gray500))

            Spacer()

            Text("\(store.collectedCount)개")
                .plobbyFont(.metricExtra)
                .foregroundStyle(Color(.gray0))
        }
        .padding(.horizontal, 16.scaled)
        .padding(.bottom, 20.scaled)
    }
}

// MARK: - 카드 뒷면

private extension CollectionCardView {

    // TODO: 디자인 확정 후 색상·여백 조정, 일러스트는 에셋 나오면 교체
    var back: some View {
        let fact = store.selectedCategory.collectionFact(count: store.collectedCount, nickname: store.nickname)

        return VStack(spacing: 0) {
            HStack {
                Text(store.selectedCategory.name)
                    .plobbyFont(.metric)
                    .foregroundStyle(Color(.gray0))

                Spacer()

                flipButton
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)

            Spacer()

            Text("지금까지 주운 \(store.selectedCategory.name)")
                .plobbyFont(.helper)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0xBA / 255, green: 0xC4 / 255, blue: 0xC0 / 255))

            Text("\(store.collectedCount)개")
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 44))
                .foregroundStyle(Color(.green500))

            // TODO: 종류별 일러스트 에셋 나오면 교체
            Text("🐢")
                .font(.system(size: 120))
                .padding(.vertical, 12)

            Text(fact.title)
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 24))
                .foregroundStyle(Color(.gray0))
                .padding(.horizontal, 24)

            Text(fact.description)
                .plobbyFont(.body)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0xBA / 255, green: 0xC4 / 255, blue: 0xC0 / 255))
                .padding(.top, 12)
                .padding(.horizontal, 24)

            Text(fact.source)
                .padding(.top, 48)
                .plobbyFont(.metadata)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0x8D / 255, green: 0x9A / 255, blue: 0x94 / 255))
                .padding(.horizontal, 24)

            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.gray900), in: RoundedRectangle(cornerRadius: 20.scaled))
    }
}

// MARK: - FlipCard

private struct FlipCard<Front: View, Back: View>: View, Animatable {

    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            front
                .opacity(angle < 90 ? 1 : 0)
                .allowsHitTesting(angle < 90)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(angle < 90 ? 0 : 1)
                .allowsHitTesting(angle >= 90)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

// MARK: - TrashCategory

private extension TrashCategory {

    func collectionFact(count: Int, nickname: String?) -> (title: String, description: String, source: String) {
        let thanks = "\(nickname.map { "\($0)님" } ?? "여러분") 덕분에"
        let count = max(count, 1)
        /// 4개마다 1마리씩 늘어나요 (1~4개 1마리, 5~8개 2마리)
        let perFour = (count + 3) / 4

        switch self {
        case .glass:
            return (
                "소라게 \(count * 9)마리를 지키는 데\n힘을 보탰어요!",
                "작은 생물이 버려진 유리병에 들어가면 빠져나오기 어려워요. \(thanks) 소라게가 새집을 찾는 길이 조금 더 안전해졌어요.",
                "출처 · 인도 야생동물연구소"
            )
        case .plastic:
            return (
                "바다거북 \(perFour)마리를 지키는 데\n힘을 보탰어요!",
                "바다거북은 물에 떠다니는 비닐을 해파리로 착각할 수 있어요. \(thanks) 바다거북이 헤엄치는 바다가 조금 더 안전해졌어요.",
                "출처 · Ocean Conservancy"
            )
        case .metal:
            return (
                "돌고래 \(count)마리를 지키는 데\n힘을 보탰어요!",
                "돌고래는 알루미늄 포일이 목에 걸리면 먹이를 삼키기 어려워요. \(thanks) 돌고래가 먹이를 찾는 바다가 조금 더 안전해졌어요.",
                "출처 · 미국 해양대기청(NOAA)"
            )
        case .wood:
            return (
                "고둥을 지키는 데\n힘을 보탰어요!",
                "버려진 방부목이 바다에 잠기면 구리 성분이 녹아내려 고둥들이 껍데기 속에 들어간 채 움직이지 못할 수 있어요. \(thanks) 고둥이 사는 갯벌이 조금 더 안전해졌어요.",
                "출처 · 뉴저지 의과대학 · 남부 캘리포니아 연안 수질 연구 프로젝트(SCCWRP)"
            )
        case .fishingGear:
            return (
                "물범 \(perFour)마리를 지키는 데\n힘을 보탰어요!",
                "물범은 버려진 그물이나 낚싯줄이 몸에 감기면 숨을 쉬러 물 위로 올라오지 못할 때도 있어요. \(thanks) 물범이 헤엄치는 바다가 조금 더 안전해졌어요.",
                "출처 · Ocean Conservancy"
            )
        case .clothing:
            return (
                "홍합을 지키는 데\n힘을 보탰어요!",
                "버려진 폴리에스터 천이 햇빛과 물살에 닳으면 아주 작은 플라스틱 섬유가 떨어져 나와요. 홍합이 먹이를 걸러 먹다가 섬유까지 삼키게 되면 성장이 눈에 띄게 더뎌질 수 있어요. \(thanks) 어린 홍합들이 자라는 바다가 조금 더 안전해졌어요.",
                "출처 · 중국환경과학연구원 · 플리머스 해양연구소"
            )
        case .styrofoam:
            return (
                "바다거북 \(count)마리를 지키는 데\n힘을 보탰어요!",
                "바다거북은 배 속에 스티로폼 조각이 쌓이면 몸이 물에 더 잘 떠서, 먹이를 찾으러 깊이 잠수하기 어려울 수 있어요. \(thanks) 바다거북이 먹이를 찾는 바다가 조금 더 안전해졌어요.",
                "출처 · Ocean Conservancy"
            )
        case .can:
            return (
                "흰동가리 \(count)마리를 지키는 데\n힘을 보탰어요!",
                "흰동가리처럼 작은 물고기는 바닷바닥에 가라앉은 캔에 들어갔다가 빠져나오지 못할 때가 있어요. \(thanks) 흰동가리가 헤엄치는 바다가 조금 더 안전해졌어요.",
                "출처 · 파트라스대학교"
            )
        case .paper:
            return (
                "플랑크톤 \(count * 3)마리를 지키는 데\n힘을 보탰어요!",
                "종이컵이 물에 오래 남으면 안쪽 코팅에서 아주 작은 플라스틱 조각이 떨어져 나올 수 있어요. \(thanks) 플랑크톤이 사는 바다가 조금 더 안전해졌어요.",
                "출처 · 아마시아대학교 · 위스퀴다르대학교"
            )
        case .rubber:
            return (
                "바닷새 \(count)마리를 지키는 데\n힘을 보탰어요!",
                "바닷새가 풍선 조각을 삼키면 먹이를 제대로 소화하기 어려워요. \(thanks) 바닷새가 먹이를 찾는 바다가 조금 더 안전해졌어요.",
                "출처 · Ocean Conservancy"
            )
        case .etc:
            return (
                "바닷물 \(count)L를 깨끗하게 지키는 데\n힘을 보탰어요!",
                "담배꽁초가 물에 잠기면 니코틴과 납 같은 성분이 녹아 나와요. \(thanks) 바다가 조금 더 안전해졌어요.",
                "출처 · 부셰르 의과대학교 · 조지아공과대학교 · 샌디에이고주립대학교"
            )
        }
    }
}

// MARK: - TrashPileView

private struct TrashPileView: View {

    private static let maximumDropCount = 200

    @State private var scene: TrashPileScene

    init(category: TrashCategory, count: Int) {
        let candidates = category.imageNames
        let scene = TrashPileScene()
        scene.scaleMode = .resizeFill
        scene.imageNames = (0..<min(count, Self.maximumDropCount)).compactMap { _ in candidates.randomElement() }
        _scene = State(initialValue: scene)
    }

    var body: some View {
        SpriteView(scene: scene)
    }
}

// MARK: - TrashPileScene

private final class TrashPileScene: SKScene {

    // MARK: - Properties

    private let trashScale: CGFloat = 0.9
    private let pileHalfWidthRatio: CGFloat = 0.46
    private let pileHeightRatio: CGFloat = 0.42
    private let fallDuration: TimeInterval = 0.25
    private let bounceHeight: CGFloat = 6
    private let maxDropDuration: TimeInterval = 2.5

    var imageNames: [String] = []
    private var hasStarted = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(resource: .gray900)
        startIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        startIfNeeded()
    }
}

// MARK: - Functions

extension TrashPileScene {

    private func startIfNeeded() {
        guard !hasStarted, size.width > 0, size.height > 0, view != nil else { return }
        hasStarted = true

        let targets = pileTargets(count: imageNames.count)
        let items = zip(imageNames, targets)
            .map { (name: $0, target: $1) }
            .sorted { $0.target.y < $1.target.y }

        let interval = maxDropDuration / Double(max(items.count, 1))
        for (index, item) in items.enumerated() {
            run(.sequence([
                .wait(forDuration: interval * Double(index)),
                .run { [weak self] in self?.drop(item.name, to: item.target) }
            ]))
        }
    }

    private func pileTargets(count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }

        let halfWidth = size.width * pileHalfWidthRatio
        let height = size.height * pileHeightRatio
        let centerX = size.width / 2

        func isInside(_ point: CGPoint) -> Bool {
            let offset = (point.x - centerX) / halfWidth
            return abs(offset) <= 1 && point.y <= height * (1 - offset * offset)
        }

        let area = 2 * halfWidth * height * 2 / 3
        let spacing = (area / CGFloat(count)).squareRoot()

        var points: [CGPoint] = []
        for y in stride(from: spacing / 2, to: height, by: spacing) {
            for x in stride(from: centerX - halfWidth + spacing / 2, to: centerX + halfWidth, by: spacing) {
                let point = CGPoint(
                    x: x + .random(in: -spacing / 2...spacing / 2),
                    y: y + .random(in: -spacing / 2...spacing / 2)
                )
                if isInside(point) { points.append(point) }
            }
        }

        while points.count < count {
            let point = CGPoint(x: .random(in: centerX - halfWidth...centerX + halfWidth), y: .random(in: 0...height))
            if isInside(point) { points.append(point) }
        }
        return Array(points.shuffled().prefix(count))
    }

    private func drop(_ name: String, to target: CGPoint) {
        let node = SKSpriteNode(imageNamed: name)
        node.setScale(DesignScale.fitRatio(for: size) * trashScale)
        node.zRotation = .random(in: -.pi...(.pi))
        node.zPosition = .random(in: 0...1)

        let cosine = abs(cos(node.zRotation))
        let sine = abs(sin(node.zRotation))
        let halfWidth = (node.size.width * cosine + node.size.height * sine) / 2
        let halfHeight = (node.size.width * sine + node.size.height * cosine) / 2
        let landing = CGPoint(
            x: min(max(target.x, halfWidth), size.width - halfWidth),
            y: min(max(target.y + halfHeight, halfHeight), size.height - halfHeight)
        )

        node.position = CGPoint(x: landing.x, y: max(size.height - halfHeight, landing.y))
        node.alpha = 0
        addChild(node)

        let move = SKAction.move(to: landing, duration: fallDuration)
        move.timingMode = .easeIn
        let fall = SKAction.group([move, .fadeIn(withDuration: fallDuration * 0.4)])
        let bounceUp = SKAction.moveBy(x: 0, y: bounceHeight, duration: 0.08)
        bounceUp.timingMode = .easeOut
        let bounceDown = bounceUp.reversed()
        bounceDown.timingMode = .easeIn

        node.run(.sequence([fall, bounceUp, bounceDown]))
    }
}
