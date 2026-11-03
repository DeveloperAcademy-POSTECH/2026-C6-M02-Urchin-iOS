//
//  BeachResponseDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

nonisolated struct BeachResponseDTO: Decodable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let region: BeachRegion
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, region, latitude, longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
