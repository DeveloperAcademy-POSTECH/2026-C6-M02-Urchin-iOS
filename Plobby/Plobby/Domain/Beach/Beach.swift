//
//  Beach.swift
//  Plobby
//
//  Created by 이은지 on 11/1/26.
//

import Foundation

nonisolated struct Beach: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let region: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

nonisolated extension Beach {
    static let all: [Beach] = {
        do {
            guard let url = Bundle.main.url(forResource: "beaches", withExtension: "json") else {
                PlobbyLogger.debug("beaches.json 파일 없음")
                return []
            }
            
            return try JSONDecoder()
                .decode([Beach].self, from: Data(contentsOf: url))
                .sorted { $0.name < $1.name }
        } catch {
            PlobbyLogger.error(error)
            return []
        }
    }()
}
