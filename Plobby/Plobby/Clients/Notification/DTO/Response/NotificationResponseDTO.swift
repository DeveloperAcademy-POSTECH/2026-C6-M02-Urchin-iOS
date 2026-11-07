//
//  NotificationResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct NotificationResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        id, type, record_id, is_read, created_at, others_count, \
        actor_nickname, beach_name, record_type, record_deleted
        """

    let id: UUID
    let type: NotificationType
    let recordID: UUID
    let isRead: Bool
    let createdAt: Date
    let othersCount: Int
    let actorNickname: String?
    let beachName: String?
    let recordType: String?
    let recordDeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id, type
        case recordID = "record_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case othersCount = "others_count"
        case actorNickname = "actor_nickname"
        case beachName = "beach_name"
        case recordType = "record_type"
        case recordDeleted = "record_deleted"
    }

    func toDomain() -> AppNotification {
        let kind: AppNotification.Kind

        switch type {
        case .like:
            kind = .like(likerNickname: actorNickname, othersCount: othersCount)
        case .beachRecord:
            kind = .newRecordAtFavoriteBeach(authorNickname: actorNickname)
        }

        return AppNotification(
            id: id,
            kind: kind,
            recordID: recordID,
            beachName: beachName,
            recordType: recordType.flatMap(RecordType.init(rawValue:)),
            isRead: isRead,
            isRecordDeleted: recordDeleted,
            createdAt: createdAt
        )
    }
}

nonisolated extension NotificationResponseDTO {

    enum NotificationType: String, Decodable, Sendable {
        case like
        case beachRecord = "beach_record"
    }
}
