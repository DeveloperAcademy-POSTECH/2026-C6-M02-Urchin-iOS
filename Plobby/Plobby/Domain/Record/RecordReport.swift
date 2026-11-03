//
//  RecordReport.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct RecordReport: Equatable, Sendable {

    let recordID: UUID
    let reason: ReportReason
    let detail: String?
}
