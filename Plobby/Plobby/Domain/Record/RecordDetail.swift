//
//  RecordDetail.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct RecordDetail: Identifiable, Equatable, Sendable {

    let id: UUID
    let userID: UUID
    let beachID: UUID
    let recordType: RecordType
    let title: String
    let startedAt: Date
    let endedAt: Date
    let weightKg: Double?
    let depthM: Double?
    let memo: String?
    let createdAt: Date
    let updatedAt: Date
    let trashCount: Int
    let photos: [Photo]
    let trash: [Trash]
}

extension RecordDetail {

    nonisolated struct Photo: Equatable, Sendable {

        enum PhotoType: String, Sendable {
            case activity
            case marineLife = "marine_life"
        }

        let storageKey: String
        let photoType: PhotoType
        let sortOrder: Int
    }

    nonisolated struct Trash: Equatable, Sendable {

        let trashCode: String
        /// 대분류 이름 (예: 유리류). 기타일 때는 `customName`을 우선 표시
        let name: String
        let customName: String?
        let quantity: Int
    }
}
