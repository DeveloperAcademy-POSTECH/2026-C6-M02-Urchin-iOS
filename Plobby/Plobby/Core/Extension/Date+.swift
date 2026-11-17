//
//  Date+.swift
//  Plobby
//
//  Created by 더스틴 on 11/9/26.
//

import Foundation

extension Date {

    /// "11월 1일"처럼 월·일만 보여줘요.
    var homeMonthDayText: String {
        formatted(.dateTime.month(.wide).day().locale(Locale(identifier: "ko_KR")))
    }

    /// 기록 목록의 날짜예요. 7일 안이면 "3일 전"처럼, 그보다 오래되면 "2026.11.01"처럼 보여줘요.
    var recordDateText: String {
        let recentLimit = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        guard self <= recentLimit else { return formatted(.relative(presentation: .numeric)) }

        return formatted(Date.VerbatimFormatStyle(
            format: "\(year: .defaultDigits).\(month: .twoDigits).\(day: .twoDigits)",
            timeZone: .current,
            calendar: .current
        ))
    }
}
