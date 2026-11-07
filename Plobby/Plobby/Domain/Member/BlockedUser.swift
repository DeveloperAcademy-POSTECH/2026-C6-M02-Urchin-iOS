//
//  BlockedUser.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

struct BlockedUser: Identifiable, Equatable {
    let id: UUID
    let nickname: String
    let profileImageKey: String?
    let profileImageURL: URL?
    let blockedAt: Date
}
