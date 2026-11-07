//
//  BeachRecord.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

/// 해변 홈의 활동 기록 한 줄
nonisolated struct BeachRecord: Equatable, Identifiable, Sendable {

    let id: UUID
    let userID: UUID
    let recordType: RecordType
    let title: String
    let startedAt: Date
    let createdAt: Date
    let nickname: String
    let profileImageURL: URL?
    let coverPhotoURL: URL?
    let trashCount: Int
    let likeCount: Int
}
