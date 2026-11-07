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
    
    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
        case reporterID = "reporter_id"
    }
}
