//
//  ConfettiBurstView.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SpriteKit
import SwiftUI

/// 체크 아이콘 위치에서 색종이가 팡 터진 뒤, 중력을 받아 떨어지며 사라지는 효과
struct ConfettiBurstView: View {

    let origin: CGPoint?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene: ConfettiScene = {
        let scene = ConfettiScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }()

    var body: some View {
        if !reduceMotion {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .allowsHitTesting(false)
                .onChange(of: origin, initial: true) { _, origin in
                    scene.burstOrigin = origin
                }
        }
    }
}
