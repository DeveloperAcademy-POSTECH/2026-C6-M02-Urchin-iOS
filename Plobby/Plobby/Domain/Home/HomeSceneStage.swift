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
    
    var isCollected: Bool {
        if case .collected = self {
            return true
        }
        
        return false
    }
}
