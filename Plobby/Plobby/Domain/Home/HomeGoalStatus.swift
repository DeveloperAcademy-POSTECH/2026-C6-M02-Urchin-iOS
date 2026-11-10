//
//  HomeGoalStatus.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

nonisolated enum HomeGoalStatus: Equatable, Sendable {
    
    case inProgress(remainingDays: Int)
    case achieved
    case ended

    var isFinished: Bool {
        remainingDays == nil
    }

    var remainingDays: Int? {
        if case let .inProgress(remainingDays) = self {
            return remainingDays
        }
        
        return nil
    }

    var chipText: String {
        switch self {
        case let .inProgress(remainingDays): remainingDays == 0 ? "D-Day" : "D-\(remainingDays)"
        case .achieved: "목표 달성"
        case .ended: "기간 종료"
        }
    }
}
