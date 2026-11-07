//
//  RecordSummary.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

/// 기록 목록(`record_feed` 뷰)의 한 항목
nonisolated struct RecordSummary: Identifiable, Equatable, Sendable {

    let id: UUID
    let userID: UUID
    let beachID: UUID
    let beachName: String
    let recordType: RecordType
    let title: String
    let startedAt: Date
    let endedAt: Date
    let weightKg: Double?
    let depthM: Double?
    let trashCount: Int
    let nickname: String
    let profileImageURL: URL?
    let coverPhotoURL: URL?
    let trashNames: String?
    let likeCount: Int
    let likedByMe: Bool
    let createdAt: Date
}
