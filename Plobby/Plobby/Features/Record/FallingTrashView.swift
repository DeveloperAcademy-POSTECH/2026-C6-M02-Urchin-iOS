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
    private let floorCategory: UInt32 = 1 << 2
    private let floorNode = SKNode()
    private let netTilt: CGFloat = .pi / 3

    var assetCounts: [ImageAsset: Int] = [:]

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
        let texture = SKTexture(imageNamed: asset.rawValue)
        let node = SKSpriteNode(texture: texture)
        node.setScale(DesignScale.fitRatio(for: size))
        
        let halfWidth = node.size.width / 2

        guard size.width > node.size.width else { return }

        let netEdgeOffset = halfWidth * 0.2
        let x = asset == .net
            ? (Bool.random() ? netEdgeOffset : size.width - netEdgeOffset)
            : .random(in: halfWidth...(size.width - halfWidth))

        node.position = CGPoint(x: x, y: size.height + node.size.height)

        let body = switch asset {
        case .tire: SKPhysicsBody(circleOfRadius: halfWidth)
        case .net: SKPhysicsBody(texture: texture, size: node.size)
        default: SKPhysicsBody(rectangleOf: node.size)
        }
        body.restitution = 0.2
        body.friction = 0.6
        body.angularVelocity = .random(in: -4...4)
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = trashCategory

        if asset == .net {
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
