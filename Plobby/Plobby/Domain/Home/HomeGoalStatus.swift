//
//  HomeGoalStatus.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

nonisolated enum HomeGoalStatus: Equatable, Sendable {
    
    /// 아직 시작하지 않은 목표예요. 시작까지 남은 날이에요.
    case upcoming(daysUntilStart: Int)
    case inProgress(remainingDays: Int)
    case achieved
    case ended

    var isFinished: Bool {
        switch self {
        case .achieved, .ended: true
        case .upcoming, .inProgress: false
        }
    }

    var remainingDays: Int? {
        if case let .inProgress(remainingDays) = self {
            return remainingDays
        }
        
        return nil
    }

    var chipText: String {
        switch self {
        case let .upcoming(daysUntilStart): daysUntilStart == 0 ? "오늘 시작" : "\(daysUntilStart)일 뒤 시작"
        case let .inProgress(remainingDays): remainingDays == 0 ? "D-Day" : "D-\(remainingDays)"
        case .achieved: "목표 달성"
        case .ended: "기간 종료"
        }
    }
}
