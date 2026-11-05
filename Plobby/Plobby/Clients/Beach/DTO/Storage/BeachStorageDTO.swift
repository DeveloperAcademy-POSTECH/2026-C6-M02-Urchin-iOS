//
//  BeachStorageDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/5/26.
//

import Foundation

/// 해변 목록을 기기 파일과 번들 JSON에 저장하고 읽을 때 쓰는 형식
nonisolated struct BeachStorageDTO: Codable, Sendable {
    let id: UUID
    let region: Region
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

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

nonisolated extension BeachStorageDTO {

    init(from beach: Beach) {
        self.init(
            id: beach.id,
            region: Region(from: beach.region),
            name: beach.name,
            address: beach.address,
            latitude: beach.latitude,
            longitude: beach.longitude
        )
    }

    enum Region: String, Codable, Sendable {
        case east, west, south, jeju

        init(from sea: Sea) {
            switch sea {
            case .east: self = .east
            case .west: self = .west
            case .south: self = .south
            case .jeju: self = .jeju
            }
        }

        func toDomain() -> Sea {
            switch self {
            case .east: .east
            case .west: .west
            case .south: .south
            case .jeju: .jeju
            }
        }
    }

    /// 앱에 포함된 `beaches.json`의 해변 목록 (이름순)
    static let bundledBeaches: [Beach] = {
        do {
            guard let url = Bundle.main.url(forResource: "beaches", withExtension: "json") else {
                PlobbyLogger.debug("beaches.json 파일 없음")
                return []
            }

            return try decode(Data(contentsOf: url))
                .sorted { $0.name < $1.name }
        } catch {
            PlobbyLogger.error(error)
            return []
        }
    }()

    static func decode(_ data: Data) throws -> [Beach] {
        try JSONDecoder()
            .decode([BeachStorageDTO].self, from: data)
            .map { $0.toDomain() }
    }

    static func encode(_ beaches: [Beach]) throws -> Data {
        try JSONEncoder().encode(beaches.map(BeachStorageDTO.init(from:)))
    }
}
