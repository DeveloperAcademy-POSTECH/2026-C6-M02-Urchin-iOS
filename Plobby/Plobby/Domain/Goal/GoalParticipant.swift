//
//  GoalParticipant.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalParticipant: Identifiable, Equatable, Sendable {
    let id: UUID
    let nickname: String
    let profileImageURL: URL?
    let collectedCount: Int
    let isBlocked: Bool
}
