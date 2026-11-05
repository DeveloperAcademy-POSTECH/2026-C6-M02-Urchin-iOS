//
//  RecordRewardView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordRewardView: View {

    let store: StoreOf<RecordRewardFeature>

    var body: some View {
        FallingTrashView(imageNames: store.trash.imageNames)
            .overlay(alignment: .bottom) {
                VStack(spacing: 8) {
                    PlobbyButton(text: "다음") {
                        store.send(.nextButtonTapped)
                    }

                    PlobbyButton(text: "닫기", style: .onlyText) {
                        store.send(.closeButtonTapped)
                    }
                }
                .padding(.horizontal, 20)
            }
    }
}

// MARK: - TrashSelection

private extension TrashSelection {

    /// 종류별 개수만 맞추고, 그 종류 안의 에셋·크기는 랜덤으로 골라요
    var imageNames: [String] {
        counts.flatMap { category, count in
            let candidates = category.imageNames
            return (0..<count).compactMap { _ in candidates.randomElement() }
        }
    }
}

// MARK: - TrashCategory

private extension TrashCategory {

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
