//
//  DependencyValues+NotificationClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Dependencies

extension DependencyValues {
    var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}
