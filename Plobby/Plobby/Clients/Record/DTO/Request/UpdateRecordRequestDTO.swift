//
//  UpdateRecordRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct UpdateRecordRequestDTO: Encodable, Sendable {
    
    let id: UUID
    let beachID: UUID
    let title: String
    let startedAt: Date
    let endedAt: Date
    let weightKg: Double?
    let depthM: Double?
    let memo: String?
    let trash: [RecordTrashRequestDTO]
    let photos: [RecordPhotoRequestDTO]

    enum CodingKeys: String, CodingKey {
        case id = "p_id"
        case beachID = "p_beach_id"
        case title = "p_title"
        case startedAt = "p_started_at"
        case endedAt = "p_ended_at"
        case weightKg = "p_weight_kg"
        case depthM = "p_depth_m"
        case memo = "p_memo"
        case trash = "p_trash"
        case photos = "p_photos"
    }

    /// RPC 파라미터는 모두 필수라 nil도 빼지 않고 null로 보내요.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(beachID, forKey: .beachID)
        try container.encode(title, forKey: .title)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(endedAt, forKey: .endedAt)
        try container.encode(weightKg, forKey: .weightKg)
        try container.encode(depthM, forKey: .depthM)
        try container.encode(memo, forKey: .memo)
        try container.encode(trash, forKey: .trash)
        try container.encode(photos, forKey: .photos)
    }
}

nonisolated extension UpdateRecordRequestDTO {
    
    /// - Parameter photoKeys: 업로드를 마친 사진과 기존 사진의 storage key. `record.photos`와 순서가 같아요.
    init(from record: UpdatedRecord, photoKeys: [String]) {
        self.init(
            id: record.id,
            beachID: record.beachID,
            title: record.title,
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            weightKg: record.weightKg,
            depthM: record.depthM,
            memo: record.memo,
            trash: record.trash.map(RecordTrashRequestDTO.init),
            photos: RecordPhotoRequestDTO.activityPhotos(photoKeys)
        )
    }
}
