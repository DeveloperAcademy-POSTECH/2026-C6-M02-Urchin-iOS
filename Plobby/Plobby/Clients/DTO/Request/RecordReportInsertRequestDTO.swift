//
//  RecordReportInsertRequestDTO.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct RecordReportInsertRequestDTO: Encodable, Sendable {
    
    let recordID: UUID
    let reporterID: UUID
    let reason: ReportReason
    let detail: String?
    
    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
        case reporterID = "reporter_id"
        case reason, detail
    }
}

nonisolated extension RecordReportInsertRequestDTO {
    
    init(from report: RecordReport, reporterID: UUID) {
        self.recordID = report.recordID
        self.reporterID = reporterID
        self.reason = report.reason
        self.detail = report.detail
    }
}
