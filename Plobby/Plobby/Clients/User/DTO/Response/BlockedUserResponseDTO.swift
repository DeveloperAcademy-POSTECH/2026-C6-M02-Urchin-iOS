//
//  BlockedUserResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

nonisolated struct BlockedUserResponseDTO: Decodable, Sendable {

    static let selectQuery = """
        blocked_id, \
        created_at, \
        blocked:users!blocked_id(profile:profiles(nickname, profile_image_key))
        """

    let blockedID: UUID
    let createdAt: Date
    let blocked: Blocked

    enum CodingKeys: String, CodingKey {
        case blockedID = "blocked_id"
        case createdAt = "created_at"
        case blocked
    }

    func toDomain() -> BlockedUser? {
        guard let profile = blocked.profile else { return nil }

        return BlockedUser(
            id: blockedID,
            nickname: profile.nickname,
            profileImageKey: profile.profileImageKey,
            blockedAt: createdAt
        )
    }
}

nonisolated extension BlockedUserResponseDTO {

    struct Blocked: Decodable, Sendable {
        let profile: Profile?
    }

    struct Profile: Decodable, Sendable {
        let nickname: String
        let profileImageKey: String?

        enum CodingKeys: String, CodingKey {
            case nickname
            case profileImageKey = "profile_image_key"
        }
    }
}
