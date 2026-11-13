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
    func 달성하면_총_개수는_달성한_순간의_개수로_고정된다() {
        let goal = makeDTO(achievedAt: GoalFixture.hours(-1), achievedCount: 1_000, collectedCount: 1_030).toDomain()

        #expect(goal.collectedCount == 1_000)
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

    /// 달성 뒤에도 목표 기간 안의 기록은 계속 이 목표에 쌓여요.
    /// 총 개수만 고정되고 플로깅·플로빙 개수는 계속 늘어서, 함께한 사람 시트와 결과 팝업의 숫자가 카드와 달라져요.
    @Test
    func 달성_후에도_활동별_개수의_합은_총_개수와_같다() {
        let goal = makeDTO(
            achievedAt: GoalFixture.hours(-1),
            achievedCount: 1_000,
            collectedCount: 1_030,
            ploggingCollectedCount: 630,
            plobbingCollectedCount: 400
        ).toDomain()

        withKnownIssue("달성 후 활동별 개수는 고정되지 않아요") {
            #expect(goal.ploggingCollectedCount + goal.plobbingCollectedCount == goal.collectedCount)
        }
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
