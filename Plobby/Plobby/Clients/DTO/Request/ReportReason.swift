//
//  ReportReason.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated enum ReportReason: String, Encodable, Sendable {
    
    case spam
    case inappropriate
    case falseInfo = "false_info"
    case other
}
