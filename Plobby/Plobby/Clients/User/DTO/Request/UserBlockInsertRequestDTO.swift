//
//  UserBlockInsertRequestDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct UserBlockInsertRequestDTO: Encodable, Sendable {
    let blockerID: UUID
    let blockedID: UUID

    enum CodingKeys: String, CodingKey {
        case blockerID = "blocker_id"
        case blockedID = "blocked_id"
    }
}
