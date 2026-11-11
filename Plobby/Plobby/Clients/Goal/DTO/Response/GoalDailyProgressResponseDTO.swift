//
//  GoalDailyProgressResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalDailyProgressResponseDTO: Decodable, Sendable {

    let day: String
    let collectedCount: Int
    let participantCount: Int

    enum CodingKeys: String, CodingKey {
        case day
        case collectedCount = "collected_count"
        case participantCount = "participant_count"
    }

    func toDomain() -> GoalDailyProgress? {
        let dayFormat = Date.ISO8601FormatStyle(timeZone: .current)
            .year()
            .month()
            .day()
        
        guard let date = try? Date(day, strategy: dayFormat) else { return nil }

        return GoalDailyProgress(
            day: date,
            collectedCount: collectedCount,
            participantCount: participantCount
        )
    }
}
