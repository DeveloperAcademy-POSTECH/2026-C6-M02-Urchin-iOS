//
//  ReadAtUpdateRequestDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct ReadAtUpdateRequestDTO: Encodable, Sendable {
    let readAt: Date

    enum CodingKeys: String, CodingKey {
        case readAt = "read_at"
    }
}
