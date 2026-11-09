//
//  CompleteSignupRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

nonisolated struct CompleteSignupRequestDTO: Encodable, Sendable {
    let nickname: String
    let profileImageKey: String?
    let beachIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case nickname = "p_nickname"
        case profileImageKey = "p_profile_image_key"
        case beachIDs = "p_beach_ids"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(profileImageKey, forKey: .profileImageKey)
        try container.encode(beachIDs, forKey: .beachIDs)
    }
}

nonisolated extension CompleteSignupRequestDTO {

    init(from profile: SignUpProfile, profileImageKey: String?) {
        self.init(
            nickname: profile.nickname,
            profileImageKey: profileImageKey,
            beachIDs: profile.favoriteBeachIDs
        )
    }
}
