//
//  ConfettiScene.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SpriteKit
import UIKit

final class ConfettiScene: SKScene {

    private let colors: [UIColor] = [
        UIColor(red: 0x44 / 255, green: 0x9B / 255, blue: 0xD9 / 255, alpha: 1),
        UIColor(red: 0xE7 / 255, green: 0xA2 / 255, blue: 0x27 / 255, alpha: 1),
        UIColor(red: 0x94 / 255, green: 0x70 / 255, blue: 0xCB / 255, alpha: 1),
        UIColor(red: 0xEB / 255, green: 0x73 / 255, blue: 0x6B / 255, alpha: 1)
    ]

    private var hasBurst = false

    var burstOrigin: CGPoint? {
        didSet { burstIfNeeded() }
    }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        burstIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        burstIfNeeded()
    }

    private func burstIfNeeded() {
        guard !hasBurst, let burstOrigin, size.width > 0, size.height > 0, view != nil else { return }
        hasBurst = true

        let center = CGPoint(x: burstOrigin.x, y: size.height - burstOrigin.y)
        let barTexture = Self.texture(size: CGSize(width: 12, height: 4), isCircle: false)
        let dotTexture = Self.texture(size: CGSize(width: 8, height: 8), isCircle: true)

        for color in colors {
            addEmitter(texture: barTexture, color: color, count: 8, at: center)
            addEmitter(texture: dotTexture, color: color, count: 2, at: center)
        }
    }

    private func addEmitter(texture: SKTexture, color: UIColor, count: Int, at position: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.particleTexture = texture
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1

        // 한 번에 다 내보내는 "팡" 효과
        emitter.particleBirthRate = 1000
        emitter.numParticlesToEmit = count
        emitter.particlePositionRange = CGVector(dx: 16, dy: 16)

        // 사방으로 퍼졌다가 중력을 받아 떨어짐
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 240.scaled
        emitter.particleSpeedRange = 120.scaled
        emitter.yAcceleration = -320.scaled

        // 뒤집히듯 돌면서, 끝날 즈음 서서히 사라짐
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = .pi * 1.5
        emitter.particleLifetime = 2.2
        emitter.particleLifetimeRange = 0.6
        emitter.particleAlphaSequence = SKKeyframeSequence(
            keyframeValues: [1, 1, 0],
            times: [0, 0.7, 1]
        )
        emitter.particleScale = DesignScale.ratio
        emitter.particleScaleRange = 0.2

        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 3.5), .removeFromParent()]))
    }

    private static func texture(size: CGSize, isCircle: Bool) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            let rect = CGRect(origin: .zero, size: size)
            if isCircle {
                context.cgContext.fillEllipse(in: rect)
            } else {
                context.fill(rect)
            }
        }
        return SKTexture(image: image)
    }
}
