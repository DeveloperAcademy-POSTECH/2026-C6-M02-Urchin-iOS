//
//  GoalParticipantResponseDTO.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalParticipantResponseDTO: Decodable, Sendable {

    let userID: UUID
    let nickname: String
    let profileImageKey: String?
    let collectedCount: Int

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nickname
        case profileImageKey = "profile_image_key"
        case collectedCount = "collected_count"
    }

    /// 차단한 사람은 프로필 사진을 비워서 기본 이미지로 보이게 해요.
    func toDomain(isBlocked: Bool, profileImageURL: (String) -> URL?) -> GoalParticipant {
        GoalParticipant(
            id: userID,
            nickname: nickname,
            profileImageURL: isBlocked ? nil : profileImageKey.flatMap(profileImageURL),
            collectedCount: collectedCount,
            isBlocked: isBlocked
        )
    }
}
