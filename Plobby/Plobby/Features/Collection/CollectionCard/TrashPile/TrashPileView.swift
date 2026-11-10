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

    @Environment(\.scenePhase) private var scenePhase

    @State private var scene: TrashPileScene = {
        let scene = TrashPileScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, isPaused: false)
            // 개수가 서버에서 늦게 도착해도, 쌓기 시작 전이면 새 개수로 쌓아요
            .onChange(of: PileInput(count: count, isActive: isActive), initial: true) { _, input in
                scene.imageNames = Self.imageNames(category: category, count: input.count)
                scene.isActive = input.isActive
                scene.isPaused = false
            }
            // 앱이 잠깐 비활성화되면(알림 센터, 제어 센터 등) SpriteKit이 장면을 멈추고 다시 풀지 않아요.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    scene.isPaused = false
                }
            }
            .onAppear {
                scene.isPaused = false
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
