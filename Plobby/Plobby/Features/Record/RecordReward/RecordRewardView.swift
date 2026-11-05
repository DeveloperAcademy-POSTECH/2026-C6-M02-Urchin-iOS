//
//  RecordRewardView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SpriteKit
import SwiftUI

import ComposableArchitecture

struct RecordRewardView: View {

    // MARK: - Properties

    let store: StoreOf<RecordRewardFeature>

    @State private var scene: FallingTrashScene

    // MARK: - Init

    init(store: StoreOf<RecordRewardFeature>) {
        self.store = store

        let scene = FallingTrashScene()
        scene.scaleMode = .resizeFill
        scene.imageNames = store.trash.imageNames
        _scene = State(initialValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                summary
            }
            .onAppear {
                store.send(.onAppear)
            }
            .overlay(alignment: .bottom) {
                PlobbyButton(text: "다음") {
                    store.send(.nextButtonTapped)
                }
                .padding(.horizontal, 20)
            }
    }
}

// MARK: - Subviews

extension RecordRewardView {

    // TODO: 디자인 확정 후 색상·여백 조정
    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let nickname = store.nickname {
                Text("\(nickname)님 덕분에")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.gray0))
                    .opacity(0.8)
                    .padding(.bottom, 8)
            }

            Text("\(store.beachName.map { "\($0)이" } ?? "바다가")\n이만큼 깨끗해졌어요")
                .plobbyFont(.headingLarge)
                .foregroundStyle(Color(.gray0))

            HStack(alignment: .top, spacing: 38) {
                metric(value: "\(store.trash.totalCount)", unit: "개", title: "수거한 쓰레기")
                    .frame(width: 154, alignment: .leading)

                if let weightKg = store.weightKg {
                    metric(value: weightKg.formatted(), unit: "kg", title: "총무게")
                }
            }
            .padding(.top, 24)
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
    }

    private func metric(value: String, unit: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 32))
                Text(unit)
                    .plobbyFont(.cardTitle)
            }
            .foregroundStyle(Color(.gray0))

            Text(title)
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.gray0))
                .opacity(0.72)
        }
    }
}

// MARK: - FallingTrashScene

private final class FallingTrashScene: SKScene {

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

// MARK: - TrashSelection

private extension TrashSelection {

    /// 종류별 개수만 맞추고, 그 종류 안의 에셋·크기는 랜덤으로 골라요
    var imageNames: [String] {
        counts.flatMap { category, count in
            let candidates = category.imageNames
            return (0..<count).compactMap { _ in candidates.randomElement() }
        }
    }
}

// MARK: - TrashCategory

private extension TrashCategory {

    var imageNames: [String] {
        assetNames.flatMap { name in
            ["S", "M", "L"]
                .map { "\(name)_\($0)" }
                .filter { UIImage(named: $0) != nil }
        }
    }

    var assetNames: [String] {
        switch self {
        case .glass:
            ["glass_bottle_brown", "glass_bottle_green", "glass_bottle_rust"]
        case .plastic:
            [
                "bottle_blue", "bottle_gray", "bottle_white", "bottle_yellow", "bottle_crumpled_yellow",
                "water_jug_blue", "water_can_pink", "water_can_yellow",
                "plastic_bag_pink", "plastic_bag_sky_blue", "plastic_bag_teal", "plastic_bag_white",
                "cup_orange", "cup_red", "tube_white", "tube_yellow", "straw_striped", "straw_yellow"
            ]
        case .metal:
            ["chopsticks_gray", "spoon_gray", "fork_gray"]
        case .wood:
            ["wood_piece_brown"]
        case .fishingGear:
            ["fishing_net_green", "fishing_trap_teal", "buoy_horizontal_orange", "buoy_vertical_orange"]
        case .clothing:
            ["tshirt_mint", "tshirt_pink", "sneaker_blue"]
        case .styrofoam:
            ["styrofoam_ver1"]
        case .can:
            ["soda_can_mint", "soda_can_pink", "soda_can_red", "tin_can_blue", "tin_can_red"]
        case .paper:
            ["crumpled_paper_white", "paper_cup_white", "spoon_white"]
        case .rubber:
            ["tire_gray"]
        case .etc:
            [
                "cigarette_butt", "battery_orange", "battery_red",
                "refrigerator_white", "washing_machine_white", "monitor_gray", "brick"
            ]
        }
    }
}
