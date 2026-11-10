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
}

enum HomeSceneTrashPhase {
    case hidden
    case scattered
    case collecting
    case collected

    init(trashDay: Int, stage: HomeSceneStage) {
        switch stage {
        case .finale:
            self = .collected
        case let .arrived(day):
            self = trashDay < day ? .collected : trashDay == day ? .scattered : .hidden
        case let .collecting(day):
            self = trashDay < day ? .collected : trashDay == day ? .collecting : .hidden
        case let .collected(day):
            self = trashDay <= day ? .collected : .hidden
        }
    }

    var opacity: Double {
        switch self {
        case .scattered, .collecting: 1
        case .hidden, .collected: 0
        }
    }

    var isAtCollector: Bool {
        switch self {
        case .collecting, .collected: true
        case .hidden, .scattered: false
        }
    }
}
