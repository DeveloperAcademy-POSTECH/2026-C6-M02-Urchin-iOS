//
//  RecordPhotoResponseDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct RecordPhotoResponseDTO: Decodable, Sendable {

    let storageKey: String
    let photoType: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case storageKey = "storage_key"
        case photoType = "photo_type"
        case sortOrder = "sort_order"
    }
}
