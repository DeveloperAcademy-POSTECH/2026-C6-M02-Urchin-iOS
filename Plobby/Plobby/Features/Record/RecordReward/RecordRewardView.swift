//
//  RecordRewardView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SpriteKit
import SwiftUI

import ComposableArchitecture

struct RecordRewardView: View {

    // MARK: - Properties

    static let curtainDuration: TimeInterval = 0.6

    let store: StoreOf<RecordRewardFeature>

    @State private var scene: FallingTrashScene
    @State private var isSummaryVisible = false

    // MARK: - Init

    init(store: StoreOf<RecordRewardFeature>) {
        self.store = store

        let scene = FallingTrashScene()
        scene.scaleMode = .resizeFill
        scene.trash = store.trash
        scene.startDelay = Self.curtainDuration
        _scene = State(initialValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                summary
                    .opacity(isSummaryVisible ? 1 : 0)
            }
            .overlay(alignment: .bottom) {
                PlobbyButton(text: "다음", style: .highlight) {
                    store.send(.nextButtonTapped)
                }
                .padding(.horizontal, 20.scaled)
                .opacity(isSummaryVisible ? 1 : 0)
                .allowsHitTesting(isSummaryVisible)
            }
            .onAppear {
                store.send(.onAppear)

                guard !store.trash.isEmpty else {
                    withAnimation(.easeInOut(duration: 0.5).delay(Self.curtainDuration)) {
                        isSummaryVisible = true
                    }
                    return
                }

                scene.onFinished = {
                    withAnimation(.easeInOut(duration: 0.5).delay(1)) {
                        isSummaryVisible = true
                    } completion: {
                        scene.startTilting()
                    }
                }
            }
    }
}

// MARK: - Subviews

extension RecordRewardView {

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let nickname = store.nickname {
                Text("\(nickname)님 덕분에")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.gray0))
                    .opacity(0.8)
                    .padding(.bottom, 8.scaled)
            }

            Text("\(store.beachName.map { "\($0)이" } ?? "바다가")\n이만큼 깨끗해졌어요")
                .plobbyFont(.headingLarge)
                .foregroundStyle(Color(.gray0))

            HStack(alignment: .top, spacing: 38.scaled) {
                if !store.trash.isEmpty {
                    metric(value: "\(store.trash.totalCount)", unit: "개", title: "수거한 쓰레기")
                        .frame(width: 154.scaled, alignment: .leading)
                }

                if let weightKg = store.weightKg {
                    metric(value: weightKg.formatted(), unit: "kg", title: "총무게")
                }
            }
            .padding(.top, 24.scaled)
        }
        .padding(.horizontal, 28.scaled)
        .padding(.top, 36.scaled)
    }

    private func metric(
        value: String,
        unit: String,
        title: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            HStack(alignment: .firstTextBaseline, spacing: 4.scaled) {
                Text(value)
                    .plobbyFont(.metricLarge)
                
                Text(unit)
                    .plobbyFont(.cardTitle)
            }
            .foregroundStyle(Color(.gray0))

            Text(title)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.gray0))
                .opacity(0.72)
        }
    }
}
