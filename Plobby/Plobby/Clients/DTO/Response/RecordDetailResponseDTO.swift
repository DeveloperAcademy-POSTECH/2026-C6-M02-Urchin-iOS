//
//  RecordDetailResponseDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

/// `records` 테이블 + `record_photos`, `record_trash` 임베드 응답
nonisolated struct RecordDetailResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        id, user_id, beach_id, record_type, title, started_at, ended_at, \
        weight_kg, depth_m, memo, created_at, updated_at, \
        record_photos(storage_key, photo_type, sort_order), \
        record_trash(trash_code, custom_name, quantity, trash_types(name_ko))
        """

    let id: UUID
    let userID: UUID
    let beachID: UUID
    let recordType: String
    let title: String
    let startedAt: Date
    let endedAt: Date
    let weightKg: Double?
    let depthM: Double?
    let memo: String?
    let createdAt: Date
    let updatedAt: Date
    let photos: [RecordPhotoResponseDTO]
    let trash: [RecordTrashResponseDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case beachID = "beach_id"
        case recordType = "record_type"
        case title
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case weightKg = "weight_kg"
        case depthM = "depth_m"
        case memo
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case photos = "record_photos"
        case trash = "record_trash"
    }
}

nonisolated extension RecordDetailResponseDTO {

    func toDomain() throws -> RecordDetail {
        guard let recordType = RecordType(rawValue: recordType) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [CodingKeys.recordType], debugDescription: "알 수 없는 record_type: \(recordType)")
            )
        }

        return RecordDetail(
            id: id,
            userID: userID,
            beachID: beachID,
            recordType: recordType,
            title: title,
            startedAt: startedAt,
            endedAt: endedAt,
            weightKg: weightKg,
            depthM: depthM,
            memo: memo,
            createdAt: createdAt,
            updatedAt: updatedAt,
            trashCount: trash.reduce(0) { $0 + $1.quantity },
            photos: photos
                .sorted { $0.sortOrder < $1.sortOrder }
                .compactMap { photo in
                    RecordDetail.Photo.PhotoType(rawValue: photo.photoType).map {
                        RecordDetail.Photo(storageKey: photo.storageKey, photoType: $0, sortOrder: photo.sortOrder)
                    }
                },
            trash: trash.map {
                RecordDetail.Trash(
                    trashCode: $0.trashCode,
                    name: $0.trashType?.nameKo ?? $0.trashCode,
                    customName: $0.customName,
                    quantity: $0.quantity
                )
            }
        )
    }
}
