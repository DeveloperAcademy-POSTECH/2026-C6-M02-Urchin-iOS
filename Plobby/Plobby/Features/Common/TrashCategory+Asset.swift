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

    var assetNames: [String] {
        switch self {
        case .glass:
            ["glass_bottle_brown", "glass_bottle_green", "glass_bottle_rust"]
        case .plastic:
            [
                "bottle_blue", "bottle_gray", "bottle_white", "bottle_yellow", "bottle_crumpled_yellow",
                "water_jug_blue", "water_can_pink", "water_can_yellow",
                "plastic_bag_pink", "plastic_bag_sky_blue", "plastic_bag_teal", "plastic_bag_white",
                "cup_orange", "cup_red", "tube_white", "tube_yellow", "straw_striped", "straw_yellow"
            ]
        case .metal:
            ["chopsticks_gray", "spoon_gray", "fork_gray"]
        case .wood:
            ["wood_piece_brown"]
        case .fishingGear:
            ["fishing_net_green", "fishing_trap_teal", "buoy_horizontal_orange", "buoy_vertical_orange"]
        case .clothing:
            ["tshirt_mint", "tshirt_pink", "sneaker_blue"]
        case .styrofoam:
            ["styrofoam_ver1"]
        case .can:
            ["soda_can_mint", "soda_can_pink", "soda_can_red", "tin_can_blue", "tin_can_red"]
        case .paper:
            ["crumpled_paper_white", "paper_cup_white", "spoon_white"]
        case .rubber:
            ["tire_gray"]
        case .etc:
            [
                "cigarette_butt", "battery_orange", "battery_red",
                "refrigerator_white", "washing_machine_white", "monitor_gray", "brick"
            ]
        }
    }
}
