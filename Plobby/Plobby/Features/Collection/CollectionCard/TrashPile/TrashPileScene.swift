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
    
    var imageNames: [String] = []
    var isActive = false {
        didSet { startIfNeeded() }
    }
    private var hasStarted = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(resource: .surfaceBlack)
        // 화면에 다시 붙을 때 멈춘 채로 남아 있으면 떨어지던 쓰레기가 그 자리에 멈춰요.
        isPaused = false
        startIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        startIfNeeded()
    }
}

// MARK: - Functions

extension TrashPileScene {

    private var ratio: CGFloat { DesignScale.fitRatio(for: size) }

    private func startIfNeeded() {
        guard isActive, !hasStarted, size.width > 0, size.height > 0, view != nil else { return }
        hasStarted = true

        let textures = imageNames.map { SKTexture(imageNamed: $0) }
        let targets = pileTargets(count: textures.count, itemExtent: averageExtent(of: textures))

        let interval = dropSpread / Double(max(textures.count, 1))
        for (index, (texture, target)) in zip(textures, targets).enumerated() {
            run(.sequence([
                .wait(forDuration: interval * Double(index)),
                .run { [weak self] in self?.drop(texture, to: target, order: index) }
            ]))
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

    private func drop(_ texture: SKTexture, to target: CGPoint, order: Int) {
        let node = SKSpriteNode(texture: texture)
        node.setScale(ratio * trashScale)
        node.zPosition = CGFloat(order)

        let finalRotation = CGFloat.random(in: -.pi...(.pi))
        let cosine = abs(cos(finalRotation))
        let sine = abs(sin(finalRotation))
        let halfWidth = (node.size.width * cosine + node.size.height * sine) / 2
        let halfHeight = (node.size.width * sine + node.size.height * cosine) / 2
        let landing = CGPoint(
            x: min(max(target.x, halfWidth), size.width - halfWidth),
            y: min(target.y + halfHeight, size.height - halfHeight)
        )

        let startY = size.height + max(node.size.width, node.size.height)
        node.position = CGPoint(x: landing.x + .random(in: -16...16) * ratio, y: startY)
        node.zRotation = finalRotation + .random(in: -0.5...0.5)
        addChild(node)

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
        let rotate = SKAction.rotate(toAngle: finalRotation, duration: fallDuration + 0.15, shortestUnitArc: true)
        rotate.timingMode = .easeOut

        node.run(.group([
            .sequence([fall, bounceUp, settle]),
            slide,
            rotate
        ]))
    }
}
