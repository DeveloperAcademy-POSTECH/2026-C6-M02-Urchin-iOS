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
}
