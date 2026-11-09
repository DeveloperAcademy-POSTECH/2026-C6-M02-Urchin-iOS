//
//  UserTrashSummaryResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct UserTrashSummaryResponseDTO: Decodable, Sendable {
    let trashCode: String
    let collectedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case trashCode = "trash_code"
        case collectedCount = "collected_count"
    }
}
