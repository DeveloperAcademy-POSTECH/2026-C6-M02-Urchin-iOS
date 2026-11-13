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
    let reason: String
    /// 기타 사유일 때만 직접 쓴 내용이 들어가요.
    let reasonDetail: String?
    
    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
        case reporterID = "reporter_id"
        case reason
        case reasonDetail = "reason_detail"
    }
}
