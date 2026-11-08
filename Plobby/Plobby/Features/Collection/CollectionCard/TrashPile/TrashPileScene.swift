//
//  TrashPileScene.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import SpriteKit

final class TrashPileScene: SKScene {

    // MARK: - Properties

    private let trashScale: CGFloat = 0.9
    private let pileHalfWidthRatio: CGFloat = 0.46
    private let pileHeightRatio: CGFloat = 0.42
    private let fallDuration: TimeInterval = 0.25
    private let bounceHeight: CGFloat = 6
    private let maxDropDuration: TimeInterval = 2.5

    var imageNames: [String] = []
    /// 카드가 화면 가운데에 올 때 true가 되고, 그때 처음 한 번만 쌓기 시작해요
    var isActive = false {
        didSet { startIfNeeded() }
    }
    private var hasStarted = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(resource: .surfaceBlack)
        startIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        startIfNeeded()
    }
}

// MARK: - Functions

extension TrashPileScene {

    private func startIfNeeded() {
        guard isActive, !hasStarted, size.width > 0, size.height > 0, view != nil else { return }
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
