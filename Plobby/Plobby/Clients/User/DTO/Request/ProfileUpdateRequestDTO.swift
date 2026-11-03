//
//  ProfileUpdateRequestDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct ProfileUpdateRequestDTO: Encodable, Sendable {
    let nickname: String
    let profileImageKey: String?

    enum CodingKeys: String, CodingKey {
        case nickname
        case profileImageKey = "profile_image_key"
    }
}
