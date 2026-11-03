//
//  CreateRecordRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/2/26.
//

import Foundation

nonisolated struct CreateRecordRequestDTO: Encodable, Sendable {
    
    let id: UUID
    let beachID: UUID
    let recordType: String
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
        case recordType = "p_record_type"
        case title = "p_title"
        case startedAt = "p_started_at"
        case endedAt = "p_ended_at"
        case weightKg = "p_weight_kg"
        case depthM = "p_depth_m"
        case memo = "p_memo"
        case trash = "p_trash"
        case photos = "p_photos"
    }
}

nonisolated extension CreateRecordRequestDTO {
    // TODO: NewRecord 엔티티 구현 후 Entity -> DTO 변환으로 교체
    init(from record: NewRecord) {
        fatalError("NewRecord가 아직 구현되지 않았어요. 임시 값으로 서버에 저장하지 않도록 막아 둬요.")
    }
}
