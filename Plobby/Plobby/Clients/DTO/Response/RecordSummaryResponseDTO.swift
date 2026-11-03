//
//  RecordSummaryResponseDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct RecordSummaryResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        id, user_id, beach_id, record_type, title, started_at, ended_at, \
        weight_kg, depth_m, created_at, \
        beaches(name), \
        users(profiles(nickname, profile_image_key)), \
        record_photos(storage_key, photo_type, sort_order), \
        record_trash(trash_code, custom_name, quantity, trash_types(name_ko)), \
        record_likes(count), \
        my_like:record_likes(user_id)
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
    let createdAt: Date
    let beach: Beach
    let user: User
    let photos: [RecordPhotoResponseDTO]
    let trash: [RecordTrashResponseDTO]
    let likes: [LikeCount]
    let myLike: [MyLike]

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
        case createdAt = "created_at"
        case beach = "beaches"
        case user = "users"
        case photos = "record_photos"
        case trash = "record_trash"
        case likes = "record_likes"
        case myLike = "my_like"
    }
}

nonisolated extension RecordSummaryResponseDTO {

    struct Beach: Decodable, Sendable {
        let name: String
    }

    struct User: Decodable, Sendable {
        let profile: Profile?

        enum CodingKeys: String, CodingKey {
            case profile = "profiles"
        }
    }

    struct Profile: Decodable, Sendable {
        let nickname: String
        let profileImageKey: String?

        enum CodingKeys: String, CodingKey {
            case nickname
            case profileImageKey = "profile_image_key"
        }
    }

    struct LikeCount: Decodable, Sendable {
        let count: Int
    }

    struct MyLike: Decodable, Sendable {
        let userID: UUID

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
        }
    }
}

nonisolated extension RecordSummaryResponseDTO {

    func toDomain() -> RecordSummary? {
        guard
            let recordType = RecordType(rawValue: recordType),
            let profile = user.profile
        else { return nil }

        let coverPhoto = photos.min {
            ($0.photoType == "activity" ? 0 : 1, $0.sortOrder) < ($1.photoType == "activity" ? 0 : 1, $1.sortOrder)
        }

        var trashNames: [String] = []
        for item in trash {
            let name = item.customName ?? item.trashType?.nameKo ?? item.trashCode
            if !trashNames.contains(name) {
                trashNames.append(name)
            }
        }

        return RecordSummary(
            id: id,
            userID: userID,
            beachID: beachID,
            beachName: beach.name,
            recordType: recordType,
            title: title,
            startedAt: startedAt,
            endedAt: endedAt,
            weightKg: weightKg,
            depthM: depthM,
            trashCount: trash.reduce(0) { $0 + $1.quantity },
            nickname: profile.nickname,
            profileImageKey: profile.profileImageKey,
            coverPhotoKey: coverPhoto?.storageKey,
            trashNames: trashNames.isEmpty ? nil : trashNames.joined(separator: ", "),
            likeCount: likes.first?.count ?? 0,
            likedByMe: !myLike.isEmpty,
            createdAt: createdAt
        )
    }
}
