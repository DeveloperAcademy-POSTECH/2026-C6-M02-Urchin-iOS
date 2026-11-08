//
//  GoalDailyProgress.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalDailyProgress: Identifiable, Equatable, Sendable {
    let day: Date
    let collectedCount: Int
    let participantCount: Int

    var id: Date { day }
}

nonisolated extension GoalDailyProgress {

    static let maximumDiverCount = 6

    /// 잠수부 애니메이션에 그릴 인원이에요. 참여자가 많아도 최대 6명까지만 그려요.
    var diverCount: Int {
        min(participantCount, Self.maximumDiverCount)
    }
}
