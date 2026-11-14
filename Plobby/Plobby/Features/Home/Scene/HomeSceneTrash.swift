//
//  HomeSceneTrash.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeSceneTrash: Identifiable {
    
    let id = UUID()
    let image: ImageResource
    let rect: CGRect
    let collector: Int
    var rotation: Double = 0

    static func scatterRotation(day: Int, index: Int) -> Double {
        let dayHash: Int = (day + 1) * 73_856_093
        let indexHash: Int = (index + 1) * 19_349_663
        let spread: Int = (dayHash ^ indexHash) % 81
        return Double(spread) - 40
    }
}

enum HomeSceneTrashPhase {
    case scattered
    case collecting
    case collected

    init(trashDay: Int, stage: HomeSceneStage) {
        switch stage {
        case .finale:
            self = .collected
        case let .arrived(day):
            self = trashDay < day ? .collected : .scattered
        case let .collecting(day):
            self = trashDay < day ? .collected : trashDay == day ? .collecting : .scattered
        case let .collected(day):
            self = trashDay <= day ? .collected : .scattered
        }
    }

    var opacity: Double {
        switch self {
        case .scattered, .collecting: 1
        case .collected: 0
        }
    }

    var isAtCollector: Bool {
        switch self {
        case .collecting, .collected: true
        case .scattered: false
        }
    }
}
