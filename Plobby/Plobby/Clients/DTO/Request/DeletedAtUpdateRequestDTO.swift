//
//  DeletedAtUpdateRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct DeletedAtUpdateRequestDTO: Encodable, Sendable {
    
    let deletedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case deletedAt = "deleted_at"
    }
}
