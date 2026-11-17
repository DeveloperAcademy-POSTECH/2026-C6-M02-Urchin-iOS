//
//  TrashCategory+Asset.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import UIKit

extension TrashCategory {

    /// 분류 목록에서 종류를 대표하는 이미지예요
    var thumbnailName: String {
        switch self {
        case .glass: "category_glass"
        case .plastic: "category_plastic"
        case .metal: "category_metal"
        case .wood: "category_wood"
        case .fishingGear: "category_fishing_gear"
        case .clothing: "category_clothing"
        case .styrofoam: "category_styrofoam"
        case .can: "category_can"
        case .paper: "category_paper"
        case .rubber: "category_rubber"
        case .etc: "category_etc"
        }
    }

    var imageNames: [String] {
        assetNames.flatMap { name in
            ["S", "M", "L"]
                .map { "\(name)_\($0)" }
                .filter { UIImage(named: $0) != nil }
        }
    }

    /// 쇼케이스용으로 고른 에셋만 애니메이션(리워드의 떨어지는 쓰레기, 컬렉션 쓰레기 더미)에 써요.
    var assetNames: [String] {
        switch self {
        case .glass:
            ["glass_bottle_brown", "glass_bottle_green", "glass_bottle_rust"]
        case .plastic:
            [
                "water_can_yellow", "water_can_pink", "water_jug_blue", "bottle_white",
                "plastic_bag_sky_blue"
            ]
        case .metal:
            ["spoon_gray", "chopsticks_gray"]
        case .wood:
            ["wood_piece_brown"]
        case .fishingGear:
            ["fishing_trap_teal", "buoy_vertical_orange"]
        case .clothing:
            ["tshirt_pink", "tshirt_mint"]
        case .styrofoam:
            ["styrofoam_ver1"]
        case .can:
            ["soda_can_red", "soda_can_pink", "tin_can_blue", "tin_can_red"]
        case .paper:
            ["paper_cup_white", "paper_bag_beige"]
        case .rubber:
            ["tire_gray"]
        case .etc:
            ["monitor_gray", "phone_gray", "washing_machine_white", "brick"]
        }
    }
}
