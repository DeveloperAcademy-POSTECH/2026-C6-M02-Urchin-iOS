//
//  HomeGoalCelebration.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 목표가 끝났을 때 장면 위로 이모지가 떠다녀요. 달성하면 기쁜 얼굴, 못 채우면 아쉬운 얼굴이에요.
struct HomeGoalCelebration: View {

    let isAchieved: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                ForEach(Self.particles.indices, id: \.self) { index in
                    let particle = Self.particles[index]
                    // 아래에서 위로 천천히 떠오르고, 좌우로 살짝 흔들려요.
                    let progress = (time / particle.duration + particle.phase).truncatingRemainder(dividingBy: 1)
                    let y = proxy.size.height * (1.05 - progress * 1.1)
                    let x = proxy.size.width * particle.x + sin(time * 1.5 + particle.phase * 6) * 8.scaled

                    Text(isAchieved ? particle.happy : "🥹")
                        .font(.system(size: particle.size.scaled))
                        .position(x: x, y: y)
                        .opacity(progress < 0.1 ? progress * 10 : progress > 0.85 ? (1 - progress) / 0.15 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension HomeGoalCelebration {

    struct Particle {
        let x: Double
        let size: CGFloat
        let duration: Double
        let phase: Double
        let happy: String
    }

    static let particles: [Particle] = [
        Particle(x: 0.12, size: 26, duration: 6.0, phase: 0.0, happy: "😊"),
        Particle(x: 0.30, size: 20, duration: 7.2, phase: 0.45, happy: "🥳"),
        Particle(x: 0.52, size: 30, duration: 6.6, phase: 0.2, happy: "😆"),
        Particle(x: 0.70, size: 22, duration: 7.8, phase: 0.7, happy: "😊"),
        Particle(x: 0.88, size: 26, duration: 6.3, phase: 0.35, happy: "🥳"),
        Particle(x: 0.40, size: 18, duration: 8.4, phase: 0.85, happy: "😆")
    ]
}
