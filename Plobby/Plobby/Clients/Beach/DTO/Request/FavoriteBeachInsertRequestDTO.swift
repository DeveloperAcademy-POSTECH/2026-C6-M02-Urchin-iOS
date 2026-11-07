//
//  FavoriteBeachInsertRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

nonisolated struct FavoriteBeachInsertRequestDTO: Encodable, Sendable {
    let userID: UUID
    let beachID: UUID

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case beachID = "beach_id"
    }
}
