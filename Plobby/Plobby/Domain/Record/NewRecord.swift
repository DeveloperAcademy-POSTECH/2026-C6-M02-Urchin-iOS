//
//  NewRecord.swift
//  Plobby
//
//  Created by 더스틴 on 11/2/26.
//

import Foundation

nonisolated struct NewRecord: Equatable, Sendable {

    let id: UUID
    let beachID: UUID
    let recordType: RecordType
    let title: String
    let startedAt: Date
    let endedAt: Date
    let weightKg: Double?
    let depthM: Double?
    let memo: String?
    let trash: [Trash]
    var photos: [RecordPhotoUpload] = []
}

extension NewRecord {

    nonisolated struct Trash: Equatable, Sendable {

        let category: TrashCategory
        let customName: String?
        let quantity: Int
    }
}

nonisolated enum NewRecordError: Error, Equatable {
    case photoUnavailable
}
