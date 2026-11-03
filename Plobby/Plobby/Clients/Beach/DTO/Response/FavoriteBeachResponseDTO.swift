//
//  FavoriteBeachResponseDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

nonisolated struct FavoriteBeachResponseDTO: Decodable, Equatable, Sendable {
    let beachID: UUID
    let createdAt: Date
    let beach: BeachResponseDTO

    enum CodingKeys: String, CodingKey {
        case beachID = "beach_id"
        case createdAt = "created_at"
        case beach
    }
}
