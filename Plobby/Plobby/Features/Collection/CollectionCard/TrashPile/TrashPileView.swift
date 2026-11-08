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

    @State private var scene: TrashPileScene

    init(category: TrashCategory, count: Int) {
        let candidates = category.imageNames
        let scene = TrashPileScene()
        scene.scaleMode = .resizeFill
        scene.imageNames = (0..<min(count, Self.maximumDropCount)).compactMap { _ in candidates.randomElement() }
        _scene = State(initialValue: scene)
    }

    var body: some View {
        SpriteView(scene: scene)
    }
}
