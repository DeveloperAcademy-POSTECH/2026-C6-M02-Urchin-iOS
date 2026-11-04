//
//  TrashCategory.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

nonisolated enum TrashCategory: String, Equatable, CaseIterable, Sendable {
    
    case glass
    case plastic
    case metal
    case wood
    case fishingGear
    case clothing
    case styrofoam
    case can
    case paper
    case rubber
    case etc
}

extension TrashCategory {
    var name: String {
        switch self {
        case .glass: "유리"
        case .plastic: "플라스틱"
        case .metal: "금속"
        case .wood: "나무"
        case .fishingGear: "낚시·어업 용품"
        case .clothing: "옷·천"
        case .styrofoam: "스티로폼"
        case .can: "캔"
        case .paper: "종이"
        case .rubber: "고무"
        case .etc: "기타"
        }
    }
    
    var examples: String {
        switch self {
        case .glass: "유리병, 유리 조각 등"
        case .plastic: "페트병, 비닐, 빨대 등"
        case .metal: "캔 제외, 금속 병뚜껑 등"
        case .wood: "나무 상자, 판자 등"
        case .fishingGear: "낚싯줄, 그물, 통발 등"
        case .clothing: "옷, 신발, 밧줄 등"
        case .styrofoam: "스티로폼 상자, 조각 등"
        case .can: "음료 캔, 통조림 캔"
        case .paper: "종이컵, 종이봉투"
        case .rubber: "타이어, 풍선"
        case .etc: "담배꽁초, 전자담배 등"
        }
    }
}
