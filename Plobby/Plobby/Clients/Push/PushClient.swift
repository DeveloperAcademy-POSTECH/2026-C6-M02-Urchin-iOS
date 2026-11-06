//
//  PushClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation
import UIKit
import UserNotifications

import Dependencies
import FirebaseMessaging

struct PushClient {
    var requestAuthorization: @Sendable () async throws -> Bool
    var fetchAuthorization: @Sendable () async -> PushAuthorization
    /// iPhone 설정 앱의 Plobby 알림 화면을 열어요. 거부된 권한은 앱에서 다시 물어볼 수 없어서 써요.
    var openNotificationSettings: @Sendable () async -> Void
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
            fetchAuthorization: {
                switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
                case .notDetermined: .notDetermined
                case .authorized, .provisional, .ephemeral: .authorized
                default: .denied
                }
            },
            openNotificationSettings: {
                guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }

                await UIApplication.shared.open(url)
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
