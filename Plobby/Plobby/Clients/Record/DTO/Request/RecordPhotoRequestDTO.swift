//
//  RecordPhotoRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct RecordPhotoRequestDTO: Encodable, Sendable {
    
    let storageKey: String
    let photoType: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case storageKey = "storage_key"
        case photoType = "photo_type"
        case sortOrder = "sort_order"
    }
}

nonisolated extension RecordPhotoRequestDTO {
    
    /// 업로드를 마친 storage key를 순서대로 활동 사진으로 보내요.
    static func activityPhotos(_ storageKeys: [String]) -> [Self] {
        storageKeys.enumerated().map { index, key in
            RecordPhotoRequestDTO(
                storageKey: key,
                photoType: RecordDetail.Photo.PhotoType.activity.rawValue,
                sortOrder: index
            )
        }
    }
}
