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

        // 알림 권한은 로그인·회원가입 직후 AppFeature에서 요청해요. APNs 등록은 권한과 상관없이 미리 해둬요.
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
