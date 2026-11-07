//
//  TimeOfDay.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import Foundation

nonisolated struct TimeOfDay: Equatable, Comparable, Sendable {
    
    let hour24: Int
    let minute: Int

    init(hour24: Int, minute: Int) {
        self.hour24 = hour24
        self.minute = minute
    }

    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour24: components.hour ?? 0, minute: components.minute ?? 0)
    }

    init(meridiem: Meridiem, hour12: Int, minute: Int) {
        self.init(
            hour24: hour12 % Self.hoursPerPeriod + (meridiem == .pm ? Self.hoursPerPeriod : 0),
            minute: minute
        )
    }

    var meridiem: Meridiem {
        hour24 < Self.hoursPerPeriod ? .am : .pm
    }

    var hour12: Int {
        let hour = hour24 % Self.hoursPerPeriod
        return hour == 0 ? Self.hoursPerPeriod : hour
    }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        (lhs.hour24, lhs.minute) < (rhs.hour24, rhs.minute)
    }
}

nonisolated extension TimeOfDay {

    static let hoursPerPeriod = 12

    enum Meridiem: String, CaseIterable, Sendable {
        case am = "오전"
        case pm = "오후"

        var startHour24: Int {
            self == .am ? 0 : TimeOfDay.hoursPerPeriod
        }
    }
}
