//
//  ActivityPeriod.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

nonisolated struct ActivityPeriod: Equatable, Sendable, Codable {
    var start: Date?
    var end: Date?
    
    subscript(field: PeriodField) -> Date? {
        get {
            switch field {
            case .start: start
            case .end: end
            }
        }
        set {
            switch field {
            case .start: start = newValue
            case .end: end = newValue
            }
        }
    }
    
    var isComplete: Bool {
        start != nil && end != nil
    }
    
    /// 시작과 종료가 모두 있고, 종료가 시작보다 늦어야 해요.
    var isValid: Bool {
        guard let start, let end else { return false }
        return start < end
    }
}
