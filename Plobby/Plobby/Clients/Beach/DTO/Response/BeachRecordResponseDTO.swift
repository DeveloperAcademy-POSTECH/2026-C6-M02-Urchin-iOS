//
//  BeachRecordResponseDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

/// 한 해변의 기록 목록 응답. 해변 홈의 기록 목록과 해변 요약을 함께 만들어요.
nonisolated struct BeachRecordResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        id, user_id, record_type, title, started_at, created_at, \
        users!records_user_id_fkey(profiles(nickname, profile_image_key)), \
        record_photos(storage_key, photo_type, sort_order), \
        record_trash(quantity), \
        record_likes(count)
        """

    let id: UUID
    let userID: UUID
    let recordType: String
    let title: String
    let startedAt: Date
    let createdAt: Date
    let user: RecordSummaryResponseDTO.User
    let photos: [RecordPhotoResponseDTO]
    let trash: [Trash]
    let likes: [RecordSummaryResponseDTO.LikeCount]

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case recordType = "record_type"
        case title
        case startedAt = "started_at"
        case createdAt = "created_at"
        case user = "users"
        case photos = "record_photos"
        case trash = "record_trash"
        case likes = "record_likes"
    }
}

nonisolated extension BeachRecordResponseDTO {

    struct Trash: Decodable, Sendable {
        let quantity: Int
    }

    /// 활동 사진을 먼저, 그 안에서는 순서대로 골라 대표 사진으로 써요.
    var coverPhotoKey: String? {
        photos.min {
            ($0.photoType == "activity" ? 0 : 1, $0.sortOrder) < ($1.photoType == "activity" ? 0 : 1, $1.sortOrder)
        }?.storageKey
    }

    func toDomain(
        photoURL: (String) -> URL?,
        profileImageURL: (String) -> URL?
    ) -> BeachRecord? {
        guard let recordType = RecordType(rawValue: recordType) else { return nil }

        return BeachRecord(
            id: id,
            userID: userID,
            recordType: recordType,
            title: title,
            startedAt: startedAt,
            createdAt: createdAt,
            nickname: user.profile?.nickname ?? "",
            profileImageURL: user.profile?.profileImageKey.flatMap(profileImageURL),
            coverPhotoURL: coverPhotoKey.flatMap(photoURL),
            trashCount: trash.reduce(0) { $0 + $1.quantity },
            likeCount: likes.first?.count ?? 0
        )
    }
}

nonisolated extension [BeachRecord] {

    /// 해변 요약을 계산해요. 기록은 최신순이어야 해요.
    /// 정화 활동·참여 인원·쓰레기 수는 차단과 상관없이 모든 기록으로 세서, 누가 봐도 같은 값이에요.
    /// 해변을 지키는 사람들은 차단한 회원도 빼지 않고 "차단한 회원"으로 보여주고, 사진에서는 빼요.
    func summary(photoLimit: Int, hiding hidden: HiddenRecords) -> BeachSummary {
        var recordCounts: [UUID: Int] = [:]
        var guardians: [UUID: BeachSummary.Guardian] = [:]
        let blockedUserIDs = Set(hidden.userIDs)
        let photoRecords = filter { !blockedUserIDs.contains($0.userID) }

        for record in self {
            let isBlocked = blockedUserIDs.contains(record.userID)
            recordCounts[record.userID, default: 0] += 1
            guardians[record.userID] = guardians[record.userID] ?? BeachSummary.Guardian(
                id: record.userID,
                nickname: record.nickname,
                profileImageURL: isBlocked ? nil : record.profileImageURL,
                isBlocked: isBlocked
            )
        }

        return BeachSummary(
            recordCount: count,
            participantCount: recordCounts.count,
            totalTrashCount: reduce(0) { $0 + $1.trashCount },
            photoURLs: [URL](photoRecords.compactMap(\.coverPhotoURL).prefix(photoLimit)),
            guardians: guardians.values.sorted {
                (recordCounts[$0.id] ?? 0, $1.nickname) > (recordCounts[$1.id] ?? 0, $0.nickname)
            }
        )
    }
}
