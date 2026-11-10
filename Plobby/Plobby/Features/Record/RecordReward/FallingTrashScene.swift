//
//  FallingTrashScene.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import CoreMotion
import SpriteKit

final class FallingTrashScene: SKScene {

    // MARK: - Properties

    private let dropInterval: TimeInterval = 0.12
    private let maxDropDuration: TimeInterval = 3.5
    private let trashScale: CGFloat = 0.8
    private let boundaryCategory: UInt32 = 1 << 0
    private let trashCategory: UInt32 = 1 << 1
    private let floorCategory: UInt32 = 1 << 2
    private let floorNode = SKNode()
    private let netTilt: CGFloat = .pi / 3
    private let settleDuration: TimeInterval = 1.5
    private let motionManager = CMMotionManager()
    private let gravityStrength: Double = 25
    private static let netNodeName = "net"

    var trash = TrashSelection()
    var startDelay: TimeInterval = 0
    var onFinished: (() -> Void)?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(resource: .neutralBlack)
        addChild(floorNode)
        updateBoundary()
        startDropping()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        updateBoundary()
    }

    override func update(_ currentTime: TimeInterval) {
        guard let gravity = motionManager.deviceMotion?.gravity else { return }

        physicsWorld.gravity = CGVector(dx: gravity.x * gravityStrength, dy: gravity.y * gravityStrength)
        for case let body? in children.map(\.physicsBody) where body.isDynamic {
            body.isResting = false
        }
        keepNetsInside()
    }

    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Functions

extension FallingTrashScene {

    private func updateBoundary() {
        let wallHeight = size.height * 3
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: wallHeight))
        path.addLine(to: .zero)
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: wallHeight))

        physicsBody = SKPhysicsBody(edgeChainFrom: path)
        physicsBody?.categoryBitMask = boundaryCategory

        floorNode.physicsBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: -size.width, y: 0),
            to: CGPoint(x: size.width * 2, y: 0)
        )
        floorNode.physicsBody?.categoryBitMask = floorCategory
    }

    func startTilting() {
        guard motionManager.isDeviceMotionAvailable, !motionManager.isDeviceMotionActive else { return }

        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        physicsBody?.categoryBitMask = boundaryCategory

        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates()
    }

    private func keepNetsInside() {
        for case let net as SKSpriteNode in children where net.name == Self.netNodeName {
            guard let body = net.physicsBody else { continue }

            let edgeOffset = net.size.width * 0.1
            let clampedX = min(max(net.position.x, edgeOffset), size.width - edgeOffset)
            let clampedY = min(net.position.y, size.height)

            if clampedX != net.position.x { body.velocity.dx = 0 }
            if clampedY != net.position.y { body.velocity.dy = 0 }
            net.position = CGPoint(x: clampedX, y: clampedY)
        }
    }

    private func startDropping() {
        let shuffled = trash.dropImageNames.shuffled()
        let items = shuffled.filter { !isNet($0) }
        let ordered = ["_L", "_M", "_S"].flatMap { suffix in items.filter { $0.hasSuffix(suffix) } }
            + shuffled.filter(isNet)

        let interval = min(dropInterval, maxDropDuration / Double(max(ordered.count, 1)))
        let wait = SKAction.wait(forDuration: interval)
        let drops = ordered.flatMap { name in
            [wait, SKAction.run { [weak self] in self?.dropItem(name) }]
        }

        run(.sequence(
            [.wait(forDuration: startDelay)]
            + drops
            + [.wait(forDuration: settleDuration), .run { [weak self] in self?.onFinished?() }]
        ))
    }

    private func isNet(_ name: String) -> Bool {
        name.hasPrefix("fishing_net")
    }

    private func dropItem(_ name: String) {
        let isNet = isNet(name)
        let texture = SKTexture(imageNamed: name)
        let node = SKSpriteNode(texture: texture)
        node.setScale(DesignScale.fitRatio(for: size) * trashScale)

        let halfWidth = node.size.width / 2

        guard size.width > node.size.width else { return }

        let netEdgeOffset = halfWidth * 0.2
        let x = isNet
            ? (Bool.random() ? netEdgeOffset : size.width - netEdgeOffset)
            : .random(in: halfWidth...(size.width - halfWidth))

        node.position = CGPoint(x: x, y: size.height + node.size.height)

        let body = if isNet {
            SKPhysicsBody(texture: texture, size: node.size)
        } else if name.hasPrefix("tire") {
            SKPhysicsBody(circleOfRadius: halfWidth)
        } else {
            SKPhysicsBody(rectangleOf: node.size)
        }
        body.restitution = 0.2
        body.friction = 0.6
        body.angularVelocity = .random(in: -4...4)
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = trashCategory

        if isNet {
            body.categoryBitMask = 0
            body.collisionBitMask = floorCategory
            body.allowsRotation = false
            body.angularVelocity = 0
            
            node.zRotation = (x < size.width / 2 ? netTilt : -netTilt) + .pi
            node.zPosition = 1
            node.name = Self.netNodeName
        }

        node.physicsBody = body

        addChild(node)
    }
}

// MARK: - TrashSelection

private extension TrashSelection {
    
    static let maximumDropCount = 50

    var dropImageNames: [String] {
        let scale = min(1, Double(Self.maximumDropCount) / Double(max(totalCount, 1)))

        return counts.flatMap { category, count in
            let dropCount = max(1, Int((Double(count) * scale).rounded()))
            let candidates = category.imageNames
            return (0..<dropCount).compactMap { _ in candidates.randomElement() }
        }
    }
}
