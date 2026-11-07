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
    
    var isValid: Bool {
        guard let start, let end else { return false }
        
        return start < end
    }
}

nonisolated extension ActivityPeriod {
    
    static let minimumGap: TimeInterval = 60
    static let defaultDuration: TimeInterval = 60 * 60
    
    static func defaultPeriod(endingAt now: Date, calendar: Calendar) -> ActivityPeriod {
        let end = calendar.dateInterval(of: .minute, for: now)?.start ?? now
        return ActivityPeriod(start: end.addingTimeInterval(-defaultDuration), end: end)
    }
    
    func allowedRange(for field: PeriodField, now: Date) -> ClosedRange<Date> {
        let lowerBound: Date
        let upperBound: Date
        
        switch field {
        case .start:
            lowerBound = .distantPast
            upperBound = (end ?? now).addingTimeInterval(-Self.minimumGap)
        case .end:
            lowerBound = start?.addingTimeInterval(Self.minimumGap) ?? .distantPast
            upperBound = now
        }
        
        return min(lowerBound, upperBound)...upperBound
    }
}

extension Comparable {
    
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
