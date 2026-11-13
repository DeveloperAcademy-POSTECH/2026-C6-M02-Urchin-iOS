//
//  GoalProgressResponseDTOTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/13/26.
//

import Foundation
import Testing
@testable import Plobby

/// 달성한 목표의 개수를 어떤 값으로 보여주는지 확인해요.
struct GoalProgressResponseDTOTests {

    @Test
    func 달성_뒤_기록이_지워져도_총_개수는_달성한_순간보다_줄지_않는다() {
        let goal = makeDTO(achievedAt: GoalFixture.hours(-1), achievedCount: 1_000, collectedCount: 990).toDomain()

        #expect(goal.collectedCount == 1_000)
    }

    /// 두 사람이 동시에 저장하면 달성한 순간의 개수에는 늦게 저장된 기록이 빠져 있어요. 실제 합계를 보여줘요.
    @Test
    func 달성과_동시에_저장된_기록도_총_개수에_넣는다() {
        let goal = makeDTO(achievedAt: GoalFixture.hours(-1), achievedCount: 1_055, collectedCount: 1_060).toDomain()

        #expect(goal.collectedCount == 1_060)
    }

    @Test
    func 달성한_순간의_개수가_없으면_지금_개수를_쓴다() {
        let goal = makeDTO(achievedAt: GoalFixture.hours(-1), achievedCount: nil, collectedCount: 1_030).toDomain()

        #expect(goal.collectedCount == 1_030)
    }

    @Test
    func 미달성이면_달성한_순간의_개수가_있어도_지금_개수를_쓴다() {
        let goal = makeDTO(achievedAt: nil, achievedCount: 1_000, collectedCount: 640).toDomain()

        #expect(goal.collectedCount == 640)
    }

    @Test
    func 달성_후에도_활동별_개수의_합은_총_개수와_같다() {
        let goal = makeDTO(
            achievedAt: GoalFixture.hours(-1),
            achievedCount: 1_055,
            collectedCount: 1_060,
            ploggingCollectedCount: 660,
            plobbingCollectedCount: 400
        ).toDomain()

        #expect(goal.ploggingCollectedCount + goal.plobbingCollectedCount == goal.collectedCount)
    }
}

// MARK: - Fixture

private extension GoalProgressResponseDTOTests {

    func makeDTO(
        achievedAt: Date?,
        achievedCount: Int?,
        collectedCount: Int,
        ploggingCollectedCount: Int = 0,
        plobbingCollectedCount: Int = 0
    ) -> GoalProgressResponseDTO {
        GoalProgressResponseDTO(
            goalID: UUID(),
            title: "테스트 목표",
            targetCount: 1_000,
            startsAt: GoalFixture.day(-2),
            endsAt: GoalFixture.day(7),
            achievedAt: achievedAt,
            achievedCount: achievedCount,
            collectedCount: collectedCount,
            ploggingCollectedCount: ploggingCollectedCount,
            plobbingCollectedCount: plobbingCollectedCount,
            participantCount: 2,
            ploggingParticipantCount: 1,
            plobbingParticipantCount: 1
        )
    }
}
