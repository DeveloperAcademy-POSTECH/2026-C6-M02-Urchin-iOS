//
//  RecordTrashRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct RecordTrashRequestDTO: Encodable, Sendable {
    
    let trashCode: String
    let customName: String?
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case trashCode = "trash_code"
        case customName = "custom_name"
        case quantity
    }
}

nonisolated extension RecordTrashRequestDTO {
    
    init(_ trash: NewRecord.Trash) {
        self.init(trashCode: trash.category.code, customName: trash.customName, quantity: trash.quantity)
    }
}
