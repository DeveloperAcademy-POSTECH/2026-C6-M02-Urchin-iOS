//
//  UpdatedRecord.swift
//  Plobby
//
//  Created by 더스틴 on 11/2/26.
//

import Foundation

nonisolated struct UpdatedRecord: Equatable, Sendable {

    let id: UUID
    let beachID: UUID
    let title: String
    let startedAt: Date
    let endedAt: Date
    let weightKg: Double?
    let depthM: Double?
    let memo: String?
    let trash: [NewRecord.Trash]
    let photos: [RecordPhotoUpload]
}

nonisolated extension UpdatedRecord {

    /// 기록 양식이 만든 값으로 기존 기록을 덮어써요. 기록 종류는 바꿀 수 없어요.
    init(_ record: NewRecord) {
        self.init(
            id: record.id,
            beachID: record.beachID,
            title: record.title,
            startedAt: record.startedAt,
            endedAt: record.endedAt,
            weightKg: record.weightKg,
            depthM: record.depthM,
            memo: record.memo,
            trash: record.trash,
            photos: record.photos
        )
    }
}
