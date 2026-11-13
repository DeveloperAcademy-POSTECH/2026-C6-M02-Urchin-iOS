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
        actor_nickname, beach_name, record_type, record_deleted, goal_id, goal_title, record_started_at
        """

    let id: UUID
    let type: NotificationType
    /// 목표 달성처럼 기록과 상관없는 알림은 비어 있어요.
    let recordID: UUID?
    let isRead: Bool
    let createdAt: Date
    let othersCount: Int
    let actorNickname: String?
    let beachName: String?
    let recordType: String?
    let recordDeleted: Bool
    /// 목표 달성 알림이 가리키는 목표예요.
    let goalID: UUID?
    /// 목표 달성 알림에 보여줄 목표 이름이에요.
    let goalTitle: String?
    /// 신고 삭제 알림에 보여줄 기록 날짜예요.
    let recordStartedAt: Date?

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
        case goalID = "goal_id"
        case goalTitle = "goal_title"
        case recordStartedAt = "record_started_at"
    }

    func toDomain() -> AppNotification {
        let kind: AppNotification.Kind

        switch type {
        case .like:
            kind = .like(likerNickname: actorNickname, othersCount: othersCount)
        case .beachRecord:
            kind = .newRecordAtFavoriteBeach(authorNickname: actorNickname)
        case .reportRemoved:
            kind = .reportRemoved
        case .goalAchieved:
            kind = .goalAchieved
        }

        return AppNotification(
            id: id,
            kind: kind,
            recordID: recordID,
            beachName: beachName,
            recordType: recordType.flatMap(RecordType.init(rawValue:)),
            isRead: isRead,
            isRecordDeleted: recordDeleted,
            goalID: goalID,
            goalTitle: goalTitle,
            recordStartedAt: recordStartedAt,
            createdAt: createdAt
        )
    }
}

nonisolated extension NotificationResponseDTO {

    enum NotificationType: String, Decodable, Sendable {
        case like
        case beachRecord = "beach_record"
        case reportRemoved = "report_removed"
        case goalAchieved = "goal_achieved"
    }
}
