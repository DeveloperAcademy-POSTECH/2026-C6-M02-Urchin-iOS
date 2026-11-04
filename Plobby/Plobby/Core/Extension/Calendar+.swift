//
//  Calendar+.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import Foundation

extension Calendar {

    /// day의 날짜에 시·분을 붙여요. 초는 0으로 맞춰요.
    func date(on day: Date, hour: Int, minute: Int) -> Date {
        date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// day의 날짜에 time의 시·분을 붙여요.
    func date(on day: Date, settingTimeOf time: Date) -> Date {
        let components = dateComponents([.hour, .minute], from: time)
        return date(on: day, hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
}
