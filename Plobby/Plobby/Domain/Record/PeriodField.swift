//
//  PeriodField.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated enum PeriodField: Equatable, Sendable {
    case start
    case end
}

extension PeriodField {
    
    var timeTitle: String {
        switch self {
        case .start: "시작 시간"
        case .end: "종료 시간"
        }
    }
    
    var dateTitle: String {
        switch self {
        case .start: "시작 날짜"
        case .end: "종료 날짜"
        }
    }
}
