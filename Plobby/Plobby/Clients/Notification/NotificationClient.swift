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
    var updateReadAt: @Sendable (_ notificationID: UUID) async throws -> Void
    var updateAllReadAt: @Sendable () async throws -> Void
    var submitDeviceToken: @Sendable (_ token: String) async throws -> Void
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
            updateReadAt: { notificationID in
                @Dependency(\.supabaseClient) var supabaseClient

                let userID = try await supabaseClient.currentUserID()

                try await supabaseClient
                    .from("notifications")
                    .update(ReadAtUpdateRequestDTO(readAt: .now), returning: .minimal)
                    .eq("id", value: notificationID)
                    .eq("user_id", value: userID)
                    .is("read_at", value: nil)
                    .execute()
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
            }
        )
    }()
}
