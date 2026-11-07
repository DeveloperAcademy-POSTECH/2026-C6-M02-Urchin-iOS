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
    let region: Region
    let address: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, region, address, latitude, longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toDomain() -> Beach {
        Beach(
            id: id,
            region: region.toDomain(),
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude
        )
    }
}

nonisolated extension BeachResponseDTO {

    enum Region: String, Decodable, Sendable {
        case east, west, south, jeju

        func toDomain() -> Sea {
            switch self {
            case .east: .east
            case .west: .west
            case .south: .south
            case .jeju: .jeju
            }
        }
    }
}
