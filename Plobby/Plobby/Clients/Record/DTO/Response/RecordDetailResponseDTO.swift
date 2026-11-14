//
//  RecordDetailResponseDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

/// `records` 테이블 + 작성자 프로필, `record_photos`, `record_trash`, 좋아요 임베드 응답
nonisolated struct RecordDetailResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        id, user_id, beach_id, record_type, title, started_at, ended_at, \
        weight_kg, depth_m, memo, created_at, updated_at, \
        users!records_user_id_fkey(profiles(nickname, profile_image_key)), \
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
    let memo: String?
    let createdAt: Date
    let updatedAt: Date
    let user: RecordSummaryResponseDTO.User
    let photos: [RecordPhotoResponseDTO]
    let trash: [RecordTrashResponseDTO]
    let likes: [RecordSummaryResponseDTO.LikeCount]
    let myLike: [RecordSummaryResponseDTO.MyLike]

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
        case user = "users"
        case photos = "record_photos"
        case trash = "record_trash"
        case likes = "record_likes"
        case myLike = "my_like"
    }
}

nonisolated extension RecordDetailResponseDTO {

    /// - Parameters:
    ///   - currentUserID: 로그인한 사용자. 둘러보기 중이면 nil이에요.
    ///   - photoURL: 기록 사진 storage key를 URL로 바꿔요.
    ///   - profileImageURL: 프로필 사진 storage key를 URL로 바꿔요.
    func toDomain(
        currentUserID: UUID?,
        photoURL: (String) -> URL?,
        profileImageURL: (String) -> URL?
    ) throws -> RecordDetail {
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
                        RecordDetail.Photo(
                            storageKey: photo.storageKey,
                            url: photoURL(photo.storageKey),
                            photoType: $0,
                            sortOrder: photo.sortOrder
                        )
                    }
                },
            // 기록하기의 쓰레기 선택, 홈의 수거대 팝업과 같은 이름·순서로 보여줘요
            trash: trash
                .sorted { $0.categoryOrder < $1.categoryOrder }
                .map {
                    RecordDetail.Trash(
                        trashCode: $0.trashCode,
                        name: TrashCategory(code: $0.trashCode)?.name ?? $0.trashType?.nameKo ?? $0.trashCode,
                        customName: $0.customName,
                        quantity: $0.quantity
                    )
                },
            nickname: user.profile?.nickname ?? "",
            profileImageURL: user.profile?.profileImageKey.flatMap(profileImageURL),
            isMine: userID == currentUserID,
            likeCount: likes.first?.count ?? 0,
            likedByMe: currentUserID.map { id in myLike.contains { $0.userID == id } } ?? false
        )
    }
}

private nonisolated extension RecordTrashResponseDTO {

    /// 쓰레기 선택 화면과 같은 순서(TrashCategory 선언 순서)로 정렬할 때 써요. 모르는 종류는 맨 뒤로 보내요.
    var categoryOrder: Int {
        TrashCategory(code: trashCode)
            .flatMap { TrashCategory.allCases.firstIndex(of: $0) } ?? TrashCategory.allCases.count
    }
}
