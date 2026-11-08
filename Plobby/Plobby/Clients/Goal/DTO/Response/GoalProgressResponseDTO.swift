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
        case collectedCount = "collected_count"
        case ploggingCollectedCount = "plogging_collected_count"
        case plobbingCollectedCount = "plobbing_collected_count"
        case participantCount = "participant_count"
        case ploggingParticipantCount = "plogging_participant_count"
        case plobbingParticipantCount = "plobbing_participant_count"
    }
    
    func toDomain() -> Goal {
        Goal(
            id: goalID,
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
