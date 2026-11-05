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
        FallingTrashView(assetCounts: store.trash.assetCounts)
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

    // ponytail: 종류마다 최대 10개만 떨어뜨림, 화면에 보여줄 개수가 정해지면 조정
    static let maximumDropCount = 10

    var assetCounts: [ImageAsset: Int] {
        counts.reduce(into: [:]) { result, item in
            let maximum = item.key.imageAsset == .net ? 1 : Self.maximumDropCount
            result[item.key.imageAsset, default: 0] += min(item.value, maximum)
        }
    }
}

// MARK: - TrashCategory

private extension TrashCategory {

    // TODO: 쓰레기 종류별 에셋 확정 후 교체 (나무·옷·스티로폼·종이는 맞는 에셋이 없어 임시 지정)
    var imageAsset: ImageAsset {
        switch self {
        case .glass: .bottleBrown
        case .plastic: .waterBottleBlue
        case .metal: .fork
        case .wood: .containerPink
        case .fishingGear: .net
        case .clothing: .tube
        case .styrofoam: .jugYellow
        case .can: .canGreen
        case .paper: .bottleOrange
        case .rubber: .tire
        case .etc: .spoon
        }
    }
}
