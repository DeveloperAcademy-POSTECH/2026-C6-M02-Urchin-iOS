//
//  ProfileResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct ProfileResponseDTO: Decodable, Sendable {
    let userID: UUID
    let nickname: String
    let profileImageKey: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nickname
        case profileImageKey = "profile_image_key"
    }

    func toDomain(profileImageURL: URL?) -> Profile {
        Profile(userID: userID, nickname: nickname, profileImageKey: profileImageKey, profileImageURL: profileImageURL)
    }
}
