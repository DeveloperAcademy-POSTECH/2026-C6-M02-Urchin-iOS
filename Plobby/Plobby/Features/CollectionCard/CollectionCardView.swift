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
        FlipCard(angle: store.isFlipped ? 180 : 0, front: front, back: back)
            .animation(.easeInOut(duration: 0.6), value: store.isFlipped)
            .padding(.horizontal, 20)
    }
}

// MARK: - Front

private extension CollectionCardView {

    var front: some View {
        VStack(spacing: 0) {
            header
            trashPile
            collectedCount
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.neutralBlack), in: RoundedRectangle(cornerRadius: 20))
    }

    var header: some View {
        HStack {
            Menu {
                ForEach(TrashCategory.allCases, id: \.self) { category in
                    Button(category.name) {
                        store.send(.categorySelected(category))
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Text(store.selectedCategory.name)
                        .plobbyFont(.metric)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(Color(.gray0))
                .fixedSize()
            }
            .id(store.selectedCategory)

            Spacer()

            flipButton
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }

    var flipButton: some View {
        Button {
            store.send(.flipButtonTapped)
        } label: {
            // TODO: 디자인 시스템 확정 후 변경
            Image(.collectionCardFlip)
                .resizable()
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .background(Color(.gray900), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.gray700), lineWidth: 1)
                }
        }
    }

    var trashPile: some View {
        TrashPileView(category: store.selectedCategory, count: store.collectedCount)
            .id(store.selectedCategory)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 16.5)
    }

    var collectedCount: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("지금까지 모은 개수")
                .plobbyFont(.helper)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0xB7 / 255, green: 0xC3 / 255, blue: 0xBC / 255))

            Spacer()

            Text("\(store.collectedCount)개")
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 44))
                .foregroundStyle(Color(.gray0))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 48)
    }
}

// MARK: - Back

private extension CollectionCardView {

    // TODO: 디자인 확정 후 색상·여백 조정, 일러스트는 에셋 나오면 교체
    var back: some View {
        let fact = store.selectedCategory.collectionFact

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

            Text(fact.description)
                .plobbyFont(.body)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0xBA / 255, green: 0xC4 / 255, blue: 0xC0 / 255))
                .padding(.top, 12)

            Text(fact.source)
                .padding(.top, 48)
                .plobbyFont(.metadata)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0x8D / 255, green: 0x9A / 255, blue: 0x94 / 255))

            Spacer()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.neutralBlack), in: RoundedRectangle(cornerRadius: 20))
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

    // TODO: 종류별 문구·출처 확정 후 교체 (지금은 플라스틱만 시안 문구)
    var collectionFact: (title: String, description: String, source: String) {
        switch self {
        case .plastic:
            (
                "바다거북이 먹이로\n착각하지 않도록",
                "비닐은 해파리와 비슷하게 보여\n바다거북이 삼킬 수 있어요.",
                "출처 · NOAA 해양쓰레기 프로그램\nIngestion"
            )
        default:
            ("바다를 깨끗하게", "\(name) 쓰레기를 주워 바다를 지켰어요.", "출처 · 준비 중")
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
        backgroundColor = .black
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

        node.position = CGPoint(x: landing.x, y: size.height + halfHeight)
        addChild(node)

        let fall = SKAction.move(to: landing, duration: fallDuration)
        fall.timingMode = .easeIn
        let bounceUp = SKAction.moveBy(x: 0, y: bounceHeight, duration: 0.08)
        bounceUp.timingMode = .easeOut
        let bounceDown = bounceUp.reversed()
        bounceDown.timingMode = .easeIn

        node.run(.sequence([fall, bounceUp, bounceDown]))
    }
}

#Preview {
    CollectionCardView(
        store: Store(initialState: CollectionCardFeature.State()) {
            CollectionCardFeature()
        }
    )
}
