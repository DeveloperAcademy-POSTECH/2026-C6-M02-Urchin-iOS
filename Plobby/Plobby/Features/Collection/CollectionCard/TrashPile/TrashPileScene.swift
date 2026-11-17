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
    private let pileSlope: CGFloat = 1.9
    private let packing: CGFloat = 0.6
    private let dropSpread: TimeInterval = 2.8
    private let fallSpeedRatio: Double = 0.8
    /// 마지막 쓰레기가 떨어지고 자리를 잡을 때까지 넉넉히 기다리는 시간이에요.
    private let settleMargin: TimeInterval = 1.0

    var imageNames: [String] = []
    var isActive = false {
        didSet { startIfNeeded() }
    }
    private var hasStarted = false

    /// 떨어뜨릴 쓰레기와 최종 위치예요. 애니메이션이 도중에 멈춰도 이 값으로 마지막 모습을 맞춰요.
    private var drops: [Drop] = []
    private var settleTask: Task<Void, Never>?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(resource: .surfaceBlack)
        // 화면에 다시 붙을 때 멈춘 채로 남아 있으면 떨어지던 쓰레기가 그 자리에 멈춰요.
        resume()
        startIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        startIfNeeded()
    }
}

// MARK: - Drop

private extension TrashPileScene {

    struct Drop {
        let texture: SKTexture
        let landing: CGPoint
        let rotation: CGFloat
        let order: Int
        var node: SKSpriteNode?
    }
}

// MARK: - Functions

extension TrashPileScene {

    private var ratio: CGFloat { DesignScale.fitRatio(for: size) }

    /// 장면과 장면을 그리는 뷰를 함께 다시 움직여요.
    /// 뷰(`SKView`)가 멈춰 있으면 장면을 풀거나 쓰레기 위치를 옮겨도 화면이 다시 그려지지 않아, 마지막 모습에 멈춰 보여요.
    func resume() {
        view?.isPaused = false
        isPaused = false
    }

    private func startIfNeeded() {
        guard isActive, !hasStarted, size.width > 0, size.height > 0, view != nil else { return }
        hasStarted = true
        resume()

        let textures = imageNames.map { SKTexture(imageNamed: $0) }
        let targets = pileTargets(count: textures.count, itemExtent: averageExtent(of: textures))
        drops = zip(textures, targets).enumerated().map { index, pair in
            makeDrop(texture: pair.0, target: pair.1, order: index)
        }

        let interval = dropSpread / Double(max(drops.count, 1))
        for index in drops.indices {
            run(.sequence([
                .wait(forDuration: interval * Double(index)),
                .run { [weak self] in self?.animateDrop(at: index) }
            ]))
        }

        // 실제 기기에서 SpriteKit이 장면을 도중에 멈추면 쓰레기가 공중에 선 채로 남아요.
        // 장면의 시계와 상관없이 실제 시간이 지나면, 남은 쓰레기를 모두 최종 위치에 놓아 쌓인 모습을 보장해요.
        let totalDuration = dropSpread + settleMargin
        settleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(totalDuration))
            guard !Task.isCancelled else { return }
            self?.settleAll()
        }
    }

    private func averageExtent(of textures: [SKTexture]) -> CGFloat {
        guard !textures.isEmpty else { return 1 }

        let total = textures.reduce(CGFloat.zero) { $0 + max($1.size().width, $1.size().height) }
        return total / CGFloat(textures.count) * ratio * trashScale
    }

    private func pileTargets(count: Int, itemExtent: CGFloat) -> [CGPoint] {
        guard count > 0 else { return [] }

        var spacing = itemExtent * packing
        var halfWidth = spacing * (CGFloat(count) / pileSlope).squareRoot()
        let maxHalfWidth = min(size.width * pileHalfWidthRatio, size.height * 0.95 / pileSlope)
        if halfWidth > maxHalfWidth {
            halfWidth = maxHalfWidth
            spacing = (pileSlope * halfWidth * halfWidth / CGFloat(count)).squareRoot()
        }
        let height = halfWidth * pileSlope
        let rowStep = spacing * 0.85
        let centerX = size.width / 2

        var points: [CGPoint] = []
        var y: CGFloat = 0
        while points.count < count {
            let rowHalfWidth = max(halfWidth * (1 - y / height), spacing / 2)
            let slots = max(1, Int(rowHalfWidth * 2 / spacing))
            let offsets = (0..<slots)
                .map { CGFloat($0) - CGFloat(slots - 1) / 2 }
                .sorted { abs($0) < abs($1) }

            var row: [CGPoint] = []
            for offset in offsets where points.count + row.count < count {
                row.append(CGPoint(
                    x: centerX + offset * spacing + .random(in: -spacing * 0.2...spacing * 0.2),
                    y: y + .random(in: 0...rowStep * 0.3)
                ))
            }
            points += row.shuffled()
            y += rowStep
        }
        return points
    }

    /// 쓰레기가 회전한 채로 화면 안에 들어오도록 최종 위치를 정해요.
    private func makeDrop(texture: SKTexture, target: CGPoint, order: Int) -> Drop {
        let scale = ratio * trashScale
        let width = texture.size().width * scale
        let height = texture.size().height * scale

        let rotation = CGFloat.random(in: -.pi...(.pi))
        let cosine = abs(cos(rotation))
        let sine = abs(sin(rotation))
        let halfWidth = (width * cosine + height * sine) / 2
        let halfHeight = (width * sine + height * cosine) / 2
        let landing = CGPoint(
            x: min(max(target.x, halfWidth), size.width - halfWidth),
            y: min(target.y + halfHeight, size.height - halfHeight)
        )
        return Drop(texture: texture, landing: landing, rotation: rotation, order: order)
    }

    private func makeNode(for drop: Drop) -> SKSpriteNode {
        let node = SKSpriteNode(texture: drop.texture)
        node.setScale(ratio * trashScale)
        node.zPosition = CGFloat(drop.order)
        addChild(node)
        return node
    }

    private func animateDrop(at index: Int) {
        guard drops.indices.contains(index), drops[index].node == nil else { return }

        let drop = drops[index]
        let node = makeNode(for: drop)
        drops[index].node = node

        let landing = drop.landing
        let startY = size.height + max(node.size.width, node.size.height)
        node.position = CGPoint(x: landing.x + .random(in: -16...16) * ratio, y: startY)
        node.zRotation = drop.rotation + .random(in: -0.5...0.5)

        let designDistance = (startY - landing.y) / ratio
        let fallDuration = (0.187 + 0.000433 * designDistance) * fallSpeedRatio
        let overshoot = 2 * ratio
        let bounce = CGFloat.random(in: 1...7) * ratio

        let fall = SKAction.moveTo(y: landing.y - overshoot, duration: fallDuration)
        fall.timingFunction = { $0 * $0 }
        let bounceUp = SKAction.moveTo(y: landing.y + bounce, duration: 0.05)
        bounceUp.timingMode = .easeOut
        let settle = SKAction.moveTo(y: landing.y, duration: 0.045)
        settle.timingMode = .easeIn

        let slide = SKAction.moveTo(x: landing.x, duration: fallDuration + 0.12)
        slide.timingMode = .easeOut
        let rotate = SKAction.rotate(toAngle: drop.rotation, duration: fallDuration + 0.15, shortestUnitArc: true)
        rotate.timingMode = .easeOut

        node.run(.group([
            .sequence([fall, bounceUp, settle]),
            slide,
            rotate
        ]))
    }

    /// 남은 쓰레기를 모두 최종 위치에 놓아요. 이미 다 떨어졌다면 겉모습은 바뀌지 않아요.
    private func settleAll() {
        resume()
        removeAllActions()

        for index in drops.indices {
            let node = drops[index].node ?? makeNode(for: drops[index])
            node.removeAllActions()
            node.position = drops[index].landing
            node.zRotation = drops[index].rotation
            drops[index].node = node
        }
    }
}
