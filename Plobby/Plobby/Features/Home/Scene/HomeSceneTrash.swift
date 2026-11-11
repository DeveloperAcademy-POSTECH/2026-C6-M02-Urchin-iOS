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
    case scattered
    case collecting
    case collected

    /// 아직 걸어가지 않은 날의 쓰레기도 해변에 흩어져 보여서, 걸어가며 주울 수 있어요.
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
