//
//  Profile.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

struct Profile: Equatable {
    let userID: UUID
    let nickname: String
    let profileImageKey: String?
    let profileImageURL: URL?
}
