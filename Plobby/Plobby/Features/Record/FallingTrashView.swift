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

    init(assetCounts: [String: Int]) {
        let scene = FallingTrashScene()
        scene.scaleMode = .resizeFill
        scene.assetCounts = assetCounts
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

    static var assetNames: [String] { largeAssetNames + smallAssetNames + [netAssetName] }

    private static let largeAssetNames = [
        "temp_trash_fridge",
        "temp_trash_washer",
        "temp_trash_monitor",
        "temp_trash_tire"
    ]
    private static let smallAssetNames = [
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
    private static let netAssetName = "temp_trash_net"
    private let tireAssetName = "temp_trash_tire"
    private let dropInterval: TimeInterval = 0.12
    private let boundaryCategory: UInt32 = 1 << 0
    private let trashCategory: UInt32 = 1 << 1

    var assetCounts: [String: Int] = [:]

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
        let assetNames = selectedAssets(from: Self.largeAssetNames).shuffled()
            + selectedAssets(from: Self.smallAssetNames).shuffled()
            + selectedAssets(from: [Self.netAssetName])
        let wait = SKAction.wait(forDuration: dropInterval)
        let actions = assetNames.flatMap { assetName in
            [wait, SKAction.run { [weak self] in self?.dropItem(named: assetName) }]
        }

        run(.sequence(actions))
    }

    private func selectedAssets(from names: [String]) -> [String] {
        names.flatMap { Array(repeating: $0, count: assetCounts[$0, default: 0]) }
    }

    private func dropItem(named assetName: String) {
        let node = SKSpriteNode(imageNamed: assetName)
        node.setScale(DesignScale.fitRatio(for: size))
        
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

        if assetName == Self.netAssetName {
            body.categoryBitMask = 0
            body.collisionBitMask = boundaryCategory
            node.zPosition = 1
        }

        node.physicsBody = body

        addChild(node)
    }
}
