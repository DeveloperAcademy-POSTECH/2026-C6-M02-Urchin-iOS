//
//  GoalParticipant.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

/// 공동 목표에 함께한 사람이에요. 내가 차단한 사람도 순위와 개수는 그대로 두고 표시만 바꿔요.
nonisolated struct GoalParticipant: Identifiable, Equatable, Sendable {
    let id: UUID
    let nickname: String
    let profileImageURL: URL?
    let collectedCount: Int
    let isBlocked: Bool
}
