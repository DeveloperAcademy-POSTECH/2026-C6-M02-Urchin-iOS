//
//  AppDelegate.swift
//  Plobby
//
//  Created by dlsundn on 10/29/26.
//

import UIKit
import UserNotifications

import FirebaseCore
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self

        Messaging.messaging().delegate = self

        // TODO: 권한 요청 시점이 정해지면 AppFeature의 pushClient.requestAuthorization으로 옮기기
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                PlobbyLogger.error(error)
            }

            PlobbyLogger.debug("푸시 권한 허용 여부: \(granted)")
        }
        application.registerForRemoteNotifications()

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging
            .messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PlobbyLogger.error(error)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        guard
            let value = userInfo["record_id"] as? String,
            let recordID = UUID(uuidString: value)
        else { return }

        PushEvents.tappedRecordIDStream.continuation.yield(recordID)
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        PlobbyLogger.debug("FCM 토큰 수신 여부: \(fcmToken != nil)")

        guard let fcmToken else { return }

        PushEvents.tokenStream.continuation.yield(fcmToken)
    }
}
