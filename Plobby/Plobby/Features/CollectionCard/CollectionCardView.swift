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
        VStack(spacing: 0) {
            header
            trashPile
            collectedCount
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.neutralBlack), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

// MARK: - Subviews

private extension CollectionCardView {

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
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }

    /// 종류가 바뀌면 장면을 새로 만들어 처음부터 다시 떨어뜨려요
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

// MARK: - TrashPileView

private struct TrashPileView: View {

    // ponytail: 모은 개수가 많아져도 버틸 수 있게 화면에 쌓는 개수를 묶어 둬요, 더미가 부족해 보이면 조정
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

/// 물리 없이 산 모양 안의 자리를 미리 정해 두고, 위에서 그 자리로 떨어뜨려요 (에셋끼리 겹쳐도 돼요)
private final class TrashPileScene: SKScene {

    // MARK: - Properties

    private let trashScale: CGFloat = 0.9
    /// 산 밑변의 절반 (화면 폭 대비)
    private let pileHalfWidthRatio: CGFloat = 0.46
    /// 산 꼭대기 높이 (화면 높이 대비)
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

    /// 장면 크기가 정해진 뒤에 한 번만 시작해요
    private func startIfNeeded() {
        guard !hasStarted, size.width > 0, size.height > 0, view != nil else { return }
        hasStarted = true

        // 아래쪽 자리부터 채워야 산이 바닥부터 쌓여요
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

    /// 둥근 산을 개수만큼의 격자 칸으로 나누고, 칸마다 하나씩 살짝 흔들어 놓아요 (빈틈 없이 고르게 채워요)
    private func pileTargets(count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }

        let halfWidth = size.width * pileHalfWidthRatio
        let height = size.height * pileHeightRatio
        let centerX = size.width / 2

        func isInside(_ point: CGPoint) -> Bool {
            let offset = (point.x - centerX) / halfWidth
            return abs(offset) <= 1 && point.y <= height * (1 - offset * offset)
        }

        // 포물선 산의 넓이(밑변 × 높이 × 2/3)를 개수로 나눈 만큼이 칸 하나의 넓이예요
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

        // 격자로 딱 맞지 않는 개수는 산 안의 아무 자리로 채우거나 덜어내요
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
        // 회전까지 반영한 실제 크기의 절반만큼 안쪽에 놓아서 영역 밖으로 잘리지 않게 해요
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
