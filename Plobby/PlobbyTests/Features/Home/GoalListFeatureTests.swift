//
//  GoalListFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/13/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

/// 홈의 "다음 목표 보기"로 여는 목표 목록이에요. 달성한 목표가 어디에 보이는지 확인해요.
@MainActor
struct GoalListFeatureTests {

    private let now = GoalFixture.now

    @Test
    func 기간이_남은_달성_목표는_진행_중_목표가_아니다() async {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-1))
        let store = TestStore(initialState: GoalListFeature.State(now: now)) {
            GoalListFeature()
        }
        store.exhaustivity = .off

        await store.send(.goalsResponse(.success([achieved])))

        #expect(store.state.currentGoal == nil)
        #expect(store.state.pastGoals.map(\.id) == [achieved.id])
    }

    @Test
    func 달성한_목표와_다음_목표가_함께_오면_다음_목표가_진행_중이다() async {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-2))
        let next = Goal.fixture(startsAt: GoalFixture.hours(-1), endsAt: GoalFixture.day(30), collectedCount: 0)
        let store = TestStore(initialState: GoalListFeature.State(now: now)) {
            GoalListFeature()
        }
        store.exhaustivity = .off

        await store.send(.goalsResponse(.success([next, achieved])))

        #expect(store.state.currentGoal?.id == next.id)
        #expect(store.state.pastGoals.map(\.id) == [achieved.id])
    }
}
