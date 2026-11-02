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
    var updateReadAt: @Sendable (_ notificationID: UUID) async throws -> Void
}

extension NotificationClient: DependencyKey {
    static let liveValue: NotificationClient = {
        .init(
            updateReadAt: { notificationID in
                @Dependency(\.supabaseClient) var supabaseClient
                
                let userID = try await supabaseClient.auth.session.user.id
        )
        }
    }
}
