//
//  Goal+Fixture.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/13/26.
//

import Foundation
@testable import Plobby

enum GoalFixture {

    static let calendar = Calendar.current

    static let now: Date = calendar.date(
        from: DateComponents(year: 2026, month: 11, day: 13, hour: 12)
    )!

    static var today: Date {
        calendar.startOfDay(for: now)
    }

    static func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today)!
    }

    static func hours(_ offset: Int) -> Date {
        calendar.date(byAdding: .hour, value: offset, to: now)!
    }
}

extension Goal {

    static func fixture(
        id: UUID = UUID(),
        title: String = "테스트 목표",
        targetCount: Int = 1_000,
        startsAt: Date = GoalFixture.day(-2),
        endsAt: Date = GoalFixture.day(7),
        achievedAt: Date? = nil,
        collectedCount: Int = 10,
        ploggingCollectedCount: Int = 6,
        plobbingCollectedCount: Int = 4,
        participantCount: Int = 2,
        ploggingParticipantCount: Int = 1,
        plobbingParticipantCount: Int = 1
    ) -> Goal {
        Goal(
            id: id,
            title: title,
            targetCount: targetCount,
            startsAt: startsAt,
            endsAt: endsAt,
            achievedAt: achievedAt,
            collectedCount: collectedCount,
            ploggingCollectedCount: ploggingCollectedCount,
            plobbingCollectedCount: plobbingCollectedCount,
            participantCount: participantCount,
            ploggingParticipantCount: ploggingParticipantCount,
            plobbingParticipantCount: plobbingParticipantCount
        )
    }
}
