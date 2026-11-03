//
//  CompleteSignupRequestDTO.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Foundation

nonisolated struct CompleteSignupRequestDTO: Encodable, Sendable {
    let name: String?
    let nickname: String
    let profileImageKey: String?
    let beachIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case name = "p_name"
        case nickname = "p_nickname"
        case profileImageKey = "p_profile_image_key"
        case beachIDs = "p_beach_ids"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(profileImageKey, forKey: .profileImageKey)
        try container.encode(beachIDs, forKey: .beachIDs)
    }
}

nonisolated extension CompleteSignupRequestDTO {
    // TODO: 프로필 이미지 업로드 구현 후 profileImageKey 연결
    init(from profile: SignUpProfile) {
        self.init(
            name: profile.name,
            nickname: profile.nickname,
            profileImageKey: nil,
            beachIDs: profile.favoriteBeachIDs
        )
    }
}
