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

    /// 서버는 날짜를 "2026-11-04" 문자열로 줘요. 그날 0시로 바꾸고, 읽지 못하면 nil이에요.
    func toDomain() -> GoalDailyProgress? {
        let dayFormat = Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
        guard let date = try? Date(day, strategy: dayFormat) else { return nil }

        return GoalDailyProgress(
            day: date,
            collectedCount: collectedCount,
            participantCount: participantCount
        )
    }
}
