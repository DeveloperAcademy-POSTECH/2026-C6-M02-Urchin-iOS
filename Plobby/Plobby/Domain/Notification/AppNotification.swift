//
//  AppNotification.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

struct AppNotification: Identifiable, Equatable {
    let id: UUID
    let kind: Kind
    let recordID: UUID
    let isRead: Bool
    let isRecordDeleted: Bool
    let createdAt: Date
}

extension AppNotification {

    enum Kind: Equatable {
        case like(likerNickname: String?)
        case newRecordAtFavoriteBeach(beachName: String)
    }
}
