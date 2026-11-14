//
//  GoalProgressResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalProgressResponseDTO: Decodable, Sendable {
    
    let goalID: UUID
    let title: String
    let targetCount: Int
    let startsAt: Date
    let endsAt: Date
    let achievedAt: Date?
    /// 달성한 순간의 개수예요. 달성 후 기록이 지워져도 이 값은 그대로예요.
    let achievedCount: Int?
    let collectedCount: Int
    let ploggingCollectedCount: Int
    let plobbingCollectedCount: Int
    let participantCount: Int
    let ploggingParticipantCount: Int
    let plobbingParticipantCount: Int
    
    enum CodingKeys: String, CodingKey {
        case goalID = "goal_id"
        case title
        case targetCount = "target_count"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case achievedAt = "achieved_at"
        case achievedCount = "achieved_count"
        case collectedCount = "collected_count"
        case ploggingCollectedCount = "plogging_collected_count"
        case plobbingCollectedCount = "plobbing_collected_count"
        case participantCount = "participant_count"
        case ploggingParticipantCount = "plogging_participant_count"
        case plobbingParticipantCount = "plobbing_participant_count"
    }
    
    /// 달성한 목표는 달성한 순간의 개수보다 줄어들지 않게 보여줘요(달성 뒤 기록이 지워진 경우).
    /// 달성과 거의 동시에 저장된 기록은 달성한 순간의 개수에 빠질 수 있어서, 더 큰 쪽(실제 합계)을 보여줘요.
    var displayedCollectedCount: Int {
        guard achievedAt != nil, let achievedCount else { return collectedCount }

        return max(collectedCount, achievedCount)
    }

    func toDomain() -> Goal {
        Goal(
            id: goalID,
            title: title,
            targetCount: targetCount,
            startsAt: startsAt,
            endsAt: endsAt,
            achievedAt: achievedAt,
            collectedCount: displayedCollectedCount,
            ploggingCollectedCount: ploggingCollectedCount,
            plobbingCollectedCount: plobbingCollectedCount,
            participantCount: participantCount,
            ploggingParticipantCount: ploggingParticipantCount,
            plobbingParticipantCount: plobbingParticipantCount
        )
    }
}
