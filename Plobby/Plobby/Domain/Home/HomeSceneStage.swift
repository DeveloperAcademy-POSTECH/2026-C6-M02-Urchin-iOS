//
//  HomeSceneStage.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import Foundation

nonisolated enum HomeSceneStage: Equatable, Sendable {
    
    case arrived(day: Int)
    case collecting(day: Int)
    case collected(day: Int)
    case finale(step: Int)
}

nonisolated extension HomeSceneStage {
    
    func day(lastDay: Int) -> Int {
        switch self {
        case let .arrived(day), let .collecting(day), let .collected(day): day
        case .finale: lastDay
        }
    }
    
    /// 쓰레기를 다 주운 마지막 날이에요. 아직 하나도 줍지 않았으면 -1, 마지막 도착점까지 갔으면 lastDay + 1이에요.
    func collectedThrough(lastDay: Int) -> Int {
        switch self {
        case let .arrived(day): day - 1
        case let .collecting(day), let .collected(day): day
        case .finale: lastDay + 1
        }
    }

    var isCollected: Bool {
        if case .collected = self {
            return true
        }
        
        return false
    }
}
