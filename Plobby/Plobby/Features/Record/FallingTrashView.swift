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

    init(assetCounts: [ImageAsset: Int]) {
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

    private let dropInterval: TimeInterval = 0.12
    private let boundaryCategory: UInt32 = 1 << 0
    private let trashCategory: UInt32 = 1 << 1

    var assetCounts: [ImageAsset: Int] = [:]

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
        let assets = selectedAssets(from: ImageAsset.large).shuffled()
            + selectedAssets(from: ImageAsset.small).shuffled()
            + selectedAssets(from: [.net])
        let wait = SKAction.wait(forDuration: dropInterval)
        let actions = assets.flatMap { asset in
            [wait, SKAction.run { [weak self] in self?.dropItem(asset) }]
        }

        run(.sequence(actions))
    }

    private func selectedAssets(from assets: [ImageAsset]) -> [ImageAsset] {
        assets.flatMap { Array(repeating: $0, count: assetCounts[$0, default: 0]) }
    }

    private func dropItem(_ asset: ImageAsset) {
        let node = SKSpriteNode(imageNamed: asset.rawValue)
        node.setScale(DesignScale.fitRatio(for: size))
        
        let halfWidth = node.size.width / 2

        guard size.width > node.size.width else { return }

        node.position = CGPoint(
            x: .random(in: halfWidth...(size.width - halfWidth)),
            y: size.height + node.size.height
        )

        let body = asset == .tire
            ? SKPhysicsBody(circleOfRadius: halfWidth)
            : SKPhysicsBody(rectangleOf: node.size)
        body.restitution = 0.2
        body.friction = 0.6
        body.angularVelocity = .random(in: -4...4)
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = trashCategory

        if asset == .net {
            body.categoryBitMask = 0
            body.collisionBitMask = boundaryCategory
            node.zPosition = 1
        }

        node.physicsBody = body

        addChild(node)
    }
}
