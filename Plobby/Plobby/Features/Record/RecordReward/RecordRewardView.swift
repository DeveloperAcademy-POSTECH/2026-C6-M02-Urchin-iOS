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

    let store: StoreOf<RecordRewardFeature>

    @State private var scene: FallingTrashScene
    @State private var isSummaryVisible = false
    @State private var isSceneRendered = false

    // MARK: - Init

    init(store: StoreOf<RecordRewardFeature>) {
        self.store = store

        let scene = FallingTrashScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor(resource: .neutralBlack)
        scene.trash = store.trash
        _scene = State(initialValue: scene)
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .opacity(isSceneRendered ? 1 : 0)
            .background(Color(.neutralBlack).ignoresSafeArea())
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

                // 앞 화면에서 바로 이어지도록 기다리지 않고 나타나요
                withAnimation(.easeOut(duration: 0.35)) {
                    isSummaryVisible = true
                }

                scene.onFinished = {
                    scene.startTilting()
                }
                scene.onFirstFrame = {
                    isSceneRendered = true
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

            if let goal = store.goal {
                goalProgress(goal)
            }
        }
        .padding(.horizontal, 28.scaled)
        .padding(.top, 36.scaled)
    }

    private func goalProgress(_ goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color(.gray0).opacity(0.22))
                .frame(width: 290.scaled, height: 1)
                .padding(.top, 12.scaled)

            Text("공통 목표")
                .plobbyFont(.helper)
                .foregroundStyle(Color(.gray0))
                .opacity(0.72)
                .padding(.top, 12.scaled)

            HStack(alignment: .firstTextBaseline) {
                Text(goal.title)
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(Color(.gray0))

                Spacer(minLength: 8.scaled)

                HStack(alignment: .firstTextBaseline, spacing: 4.scaled) {
                    Text("\(goal.collectedCount)")
                        .plobbyFont(.cardTitle)
                        .foregroundStyle(Color(.brandPrimary))

                    Text("/ \(goal.targetCount)개")
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.gray0))
                        .opacity(0.72)
                }
            }
            .frame(width: 290.scaled)
            .padding(.top, 4.scaled)
        }
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
