//
//  FallingTrashView.swift
//  Plobby
//
//  Created by 이은지 on 11/2/26.
//

import UIKit
import SpriteKit
import SwiftUI

struct FallingTrashView: View {

    // MARK: - Properties

    @State private var scene: FallingTrashScene

    // MARK: - Init

    init(imageNames: [String]) {
        let scene = FallingTrashScene()
        scene.scaleMode = .resizeFill
        scene.imageNames = imageNames
        _scene = State(initialValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

final class FallingTrashScene: SKScene {

    // MARK: - Properties

    private let dropInterval: TimeInterval = 0.12
    private let boundaryCategory: UInt32 = 1 << 0
    private let trashCategory: UInt32 = 1 << 1
    private let floorCategory: UInt32 = 1 << 2
    private let floorNode = SKNode()
    private let netTilt: CGFloat = .pi / 3

    var imageNames: [String] = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        addChild(floorNode)
        updateBoundary()
        startDropping()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        updateBoundary()
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

    private func startDropping() {
        // 큰 것부터 바닥에 깔리도록 L → M → S 순서로 떨어뜨리고, 그물은 맨 마지막에 덮어요
        let shuffled = imageNames.shuffled()
        let items = shuffled.filter { !isNet($0) }
        let ordered = ["_L", "_M", "_S"].flatMap { suffix in items.filter { $0.hasSuffix(suffix) } }
            + shuffled.filter(isNet)

        let wait = SKAction.wait(forDuration: dropInterval)
        let actions = ordered.flatMap { name in
            [wait, SKAction.run { [weak self] in self?.dropItem(name) }]
        }

        run(.sequence(actions))
    }

    private func isNet(_ name: String) -> Bool {
        name.hasPrefix("fishing_net")
    }

    private func dropItem(_ name: String) {
        let isNet = isNet(name)
        let texture = SKTexture(imageNamed: name)
        let node = SKSpriteNode(texture: texture)
        node.setScale(DesignScale.fitRatio(for: size))
        
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
            node.zRotation = x < size.width / 2 ? netTilt : -netTilt
            node.zPosition = 1
        }

        node.physicsBody = body

        addChild(node)
    }
}
