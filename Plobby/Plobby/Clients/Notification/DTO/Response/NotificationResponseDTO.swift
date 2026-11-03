//
//  NotificationResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct NotificationResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        id, type, record_id, read_at, created_at, actor_nickname, beach_name, record_deleted
        """

    let id: UUID
    let type: NotificationType
    let recordID: UUID
    let readAt: Date?
    let createdAt: Date
    let actorNickname: String?
    let beachName: String
    let recordDeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id, type
        case recordID = "record_id"
        case readAt = "read_at"
        case createdAt = "created_at"
        case actorNickname = "actor_nickname"
        case beachName = "beach_name"
        case recordDeleted = "record_deleted"
    }

    func toDomain() -> AppNotification {
        let kind: AppNotification.Kind

        switch type {
        case .like:
            kind = .like(likerNickname: actorNickname)
        case .beachRecord:
            kind = .newRecordAtFavoriteBeach(beachName: beachName)
        }

        return AppNotification(
            id: id,
            kind: kind,
            recordID: recordID,
            isRead: readAt != nil,
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
