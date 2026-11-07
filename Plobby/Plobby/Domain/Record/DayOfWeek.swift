//
//  DayOfWeek.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

enum DayOfWeek: CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

extension DayOfWeek {
    
    var koreanName: String {
        switch self {
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        case .sunday: "일"
        }
    }
}
