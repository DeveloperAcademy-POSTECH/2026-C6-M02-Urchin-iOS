//
//  FavoriteBeachResponseDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

struct FavoriteBeachResponseDTO: Decodable, Equatable {
    let beachId: UUID
    let createdAt: Date
    let beach: BeachResponseDTO

    enum CodingKeys: String, CodingKey {
        case beachId = "beach_id"
        case createdAt = "created_at"
        case beach
    }
}
