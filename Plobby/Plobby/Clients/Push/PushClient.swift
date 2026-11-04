//
//  PushClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation
import UserNotifications

import Dependencies
import FirebaseMessaging

struct PushClient {
    var requestAuthorization: @Sendable () async throws -> Bool
    var fetchToken: @Sendable () async throws -> String
    var tokens: @Sendable () -> AsyncStream<String>
    var tappedRecordIDs: @Sendable () -> AsyncStream<UUID>
}

extension PushClient: DependencyKey {
    static let liveValue: PushClient = {
        .init(
            requestAuthorization: {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            },
            fetchToken: {
                try await Messaging.messaging().token()
            },
            tokens: {
                PushEvents.tokenStream.stream
            },
            tappedRecordIDs: {
                PushEvents.tappedRecordIDStream.stream
            }
        )
    }()
}
