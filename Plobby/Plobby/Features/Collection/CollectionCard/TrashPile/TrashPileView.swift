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

    let isActive: Bool

    @State private var scene: TrashPileScene

    init(category: TrashCategory, count: Int, isActive: Bool) {
        self.isActive = isActive
        let candidates = category.imageNames
        let scene = TrashPileScene()
        scene.scaleMode = .resizeFill
        scene.imageNames = (0..<min(count, Self.maximumDropCount)).compactMap { _ in candidates.randomElement() }
        _scene = State(initialValue: scene)
    }

    var body: some View {
        SpriteView(scene: scene)
            .onChange(of: isActive, initial: true) { _, isActive in
                scene.isActive = isActive
            }
    }
}
