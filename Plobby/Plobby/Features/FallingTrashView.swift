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

    @State private var scene: FallingTrashScene = {
        let scene = FallingTrashScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}

final class FallingTrashScene: SKScene {

    // MARK: - Properties

    private let largeAssetNames = [
        "temp_trash_fridge",
        "temp_trash_washer",
        "temp_trash_monitor",
        "temp_trash_tire"
    ]
    private let smallAssetNames = [
        "temp_trash_jug_yellow",
        "temp_trash_water_jug_blue",
        "temp_trash_water_bottle_blue",
        "temp_trash_bottle_brown",
        "temp_trash_bottle_orange",
        "temp_trash_bottle_green",
        "temp_trash_can_orange",
        "temp_trash_can_green",
        "temp_trash_container_pink",
        "temp_trash_tube",
        "temp_trash_spoon",
        "temp_trash_fork"
    ]
    private let netAssetName = "temp_trash_net"
    private let tireAssetName = "temp_trash_tire"
    private let smallAssetCopies = 2
    private let dropInterval: TimeInterval = 0.12
    private let boundaryCategory: UInt32 = 1 << 0
    private let trashCategory: UInt32 = 1 << 1

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
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
    }

    private func startDropping() {
        let smallAssets = Array(repeating: smallAssetNames, count: smallAssetCopies).flatMap { $0 }.shuffled()
        let assetNames = largeAssetNames.shuffled() + smallAssets + [netAssetName]
        let wait = SKAction.wait(forDuration: dropInterval)
        let actions = assetNames.flatMap { assetName in
            [wait, SKAction.run { [weak self] in self?.dropItem(named: assetName) }]
        }

        run(.sequence(actions))
    }

    private func dropItem(named assetName: String) {
        let node = SKSpriteNode(imageNamed: assetName)
        let halfWidth = node.size.width / 2

        guard size.width > node.size.width else { return }

        node.position = CGPoint(
            x: .random(in: halfWidth...(size.width - halfWidth)),
            y: size.height + node.size.height
        )

        let body = assetName == tireAssetName
            ? SKPhysicsBody(circleOfRadius: halfWidth)
            : SKPhysicsBody(rectangleOf: node.size)
        body.restitution = 0.2
        body.friction = 0.6
        body.angularVelocity = .random(in: -4...4)
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = trashCategory

        if assetName == netAssetName {
            body.categoryBitMask = 0
            body.collisionBitMask = boundaryCategory
            node.zPosition = 1
        }

        node.physicsBody = body

        addChild(node)
    }
}
