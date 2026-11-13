//
//  NotificationClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

import Dependencies
import Supabase

struct NotificationClient {
    var fetchNotifications: @Sendable () async throws -> [AppNotification]
    /// 알림을 읽음 처리해요. 좋아요 알림은 같은 기록에 묶인 알림을 모두 읽음 처리해요.
    var updateReadAt: @Sendable (_ notification: AppNotification) async throws -> Void
    var updateAllReadAt: @Sendable () async throws -> Void
    var submitDeviceToken: @Sendable (_ token: String) async throws -> Void
    /// 이 기기로 푸시를 받지 않도록 서버에서 기기 토큰을 지워요.
    var removeDeviceToken: @Sendable (_ token: String) async throws -> Void
}

extension NotificationClient: DependencyKey {
    static let liveValue: NotificationClient = {
        .init(
            fetchNotifications: {
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.currentUserID()

                let notifications: [NotificationResponseDTO] = try await supabaseClient
                    .from("notification_list")
                    .select(NotificationResponseDTO.selectQuery)
                    .eq("user_id", value: userID)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                return notifications.map { $0.toDomain() }
            },
            updateReadAt: { notification in
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.currentUserID()

                var query = try supabaseClient
                    .from("notifications")
                    .update(ReadAtUpdateRequestDTO(readAt: .now), returning: .minimal)
                    .eq("user_id", value: userID)
                    .eq("type", value: notification.kind.serverType)
                    .is("read_at", value: nil)

                query = notification.recordID != nil
                    ? query.eq("record_id", value: notification.recordID)
                    : query.eq("id", value: notification.id)

                try await query.execute()
            },
            updateAllReadAt: {
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.currentUserID()

                try await supabaseClient
                    .from("notifications")
                    .update(ReadAtUpdateRequestDTO(readAt: .now), returning: .minimal)
                    .eq("user_id", value: userID)
                    .is("read_at", value: nil)
                    .execute()
            },
            submitDeviceToken: { token in
                @Dependency(\.supabaseClient) var supabaseClient

                try await supabaseClient
                    .rpc("register_device_token", params: RegisterDeviceTokenRequestDTO(token: token))
                    .execute()
            },
            removeDeviceToken: { token in
                @Dependency(\.supabaseClient) var supabaseClient

                try await supabaseClient
                    .from("device_tokens")
                    .delete(returning: .minimal)
                    .eq("token", value: token)
                    .execute()
            }
        )
    }()
}

// MARK: - AppNotification.Kind+

private nonisolated extension AppNotification.Kind {

    /// `notifications.type` 칼럼 값
    var serverType: String {
        switch self {
        case .like: "like"
        case .newRecordAtFavoriteBeach: "beach_record"
        case .reportRemoved: "report_removed"
        case .goalAchieved: "goal_achieved"
        }
    }
}
