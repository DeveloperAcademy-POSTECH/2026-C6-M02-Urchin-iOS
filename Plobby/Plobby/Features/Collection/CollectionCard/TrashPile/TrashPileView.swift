//
//  TrashPileView.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import SpriteKit
import SwiftUI

struct TrashPileView: View {

    private static let maximumDropCount = 200

    let category: TrashCategory
    let count: Int
    let isActive: Bool

    @State private var scene: TrashPileScene = {
        let scene = TrashPileScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene)
            // 개수가 서버에서 늦게 도착해도, 쌓기 시작 전이면 새 개수로 쌓아요
            .onChange(of: PileInput(count: count, isActive: isActive), initial: true) { _, input in
                scene.imageNames = Self.imageNames(category: category, count: input.count)
                scene.isActive = input.isActive
            }
    }

    private static func imageNames(category: TrashCategory, count: Int) -> [String] {
        let candidates = category.imageNames
        return (0..<min(count, maximumDropCount)).compactMap { _ in candidates.randomElement() }
    }
}

private struct PileInput: Equatable {
    let count: Int
    let isActive: Bool
}
