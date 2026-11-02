//
//  FavoriteBeachInsertRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

struct FavoriteBeachInsertRequestDTO: Encodable {
    let userId: UUID
    let beachId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case beachId = "beach_id"
    }
}
