//
//  GoalTrashSummaryResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalTrashSummaryResponseDTO: Decodable, Sendable {

    let trashCode: String
    let collectedCount: Int

    enum CodingKeys: String, CodingKey {
        case trashCode = "trash_code"
        case collectedCount = "collected_count"
    }

    func toDomain() -> GoalTrashSummary? {
        guard let category = TrashCategory(code: trashCode) else { return nil }

        return GoalTrashSummary(category: category, collectedCount: collectedCount)
    }
}
