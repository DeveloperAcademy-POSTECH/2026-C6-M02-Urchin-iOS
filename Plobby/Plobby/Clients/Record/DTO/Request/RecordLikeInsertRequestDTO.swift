//
//  RecordLikeInsertRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct RecordLikeInsertRequestDTO: Encodable, Sendable {
    
    let recordID: UUID
    let userID: UUID
    
    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
        case userID = "user_id"
    }
}
