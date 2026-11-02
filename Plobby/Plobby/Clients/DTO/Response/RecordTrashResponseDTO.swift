//
//  RecordTrashResponseDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct RecordTrashResponseDTO: Decodable, Sendable {

    struct TrashType: Decodable, Sendable {
        let nameKo: String

        enum CodingKeys: String, CodingKey {
            case nameKo = "name_ko"
        }
    }

    let trashCode: String
    let customName: String?
    let quantity: Int
    let trashType: TrashType?

    enum CodingKeys: String, CodingKey {
        case trashCode = "trash_code"
        case customName = "custom_name"
        case quantity
        case trashType = "trash_types"
    }
}
