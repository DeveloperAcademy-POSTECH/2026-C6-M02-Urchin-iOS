//
//  FlipCard.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import SwiftUI

struct FlipCard<Front: View, Back: View>: View, Animatable {

    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            front
                .opacity(angle < 90 ? 1 : 0)
                .allowsHitTesting(angle < 90)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(angle < 90 ? 0 : 1)
                .allowsHitTesting(angle >= 90)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}
