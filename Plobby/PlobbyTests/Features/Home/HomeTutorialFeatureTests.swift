//
//  HomeTutorialFeatureTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 11/13/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

/// 처음 가입한 사용자에게 한 번만 보여주는 홈 튜토리얼의 흐름을 확인해요.
@MainActor
@Suite(.serialized)
struct HomeTutorialFeatureTests {

    // MARK: - 시작

    @Test
    func 대기_중이면_홈에_들어올_때_플로깅으로_튜토리얼을_시작한다() async {
        @Shared(.isHomeTutorialPending) var isHomeTutorialPending = false
        $isHomeTutorialPending.withLock { $0 = true }
        // ImmediateClock이면 3초 자동 전환이 바로 실행돼서, 시작 단계를 보려면 시간을 멈춰 둬요.
        let store = makeStore(clock: TestClock())

        await store.send(.onAppear)

        #expect(store.state.tutorialStep == .goal)
        #expect(store.state.tutorialRecordType == .plogging)
        #expect(store.state.selectedType == .plogging)
        await store.skipInFlightEffects()
    }

    @Test
    func 대기_중이_아니면_튜토리얼을_시작하지_않는다() async {
        @Shared(.isHomeTutorialPending) var isHomeTutorialPending = false
        $isHomeTutorialPending.withLock { $0 = false }
        let store = makeStore()

        await store.send(.onAppear)

        #expect(store.state.tutorialStep == nil)
    }

    // MARK: - 첫 안내 자동 전환

    @Test
    func 첫_안내는_3초_뒤_펼치기_안내로_넘어간다() async {
        @Shared(.isHomeTutorialPending) var isHomeTutorialPending = false
        $isHomeTutorialPending.withLock { $0 = true }
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.onAppear)
        await clock.advance(by: HomeFeature.tutorialIntroDuration)
        await store.receive(\.tutorialIntroFinished)

        #expect(store.state.tutorialStep == .goalToggle)
    }

    @Test
    func 자동_전환_전에_눌러서_넘겼으면_시간이_지나도_다시_넘어가지_않는다() async {
        @Shared(.isHomeTutorialPending) var isHomeTutorialPending = false
        $isHomeTutorialPending.withLock { $0 = true }
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.onAppear)
        await store.send(.tutorialAdvanced)
        await store.send(.tutorialAdvanced)
        #expect(store.state.tutorialStep == .goalFill)

        await clock.advance(by: HomeFeature.tutorialIntroDuration)
        await store.receive(\.tutorialIntroFinished)

        #expect(store.state.tutorialStep == .goalFill)
    }

    // MARK: - 플로빙 전환

    @Test
    func 플로깅_기록_결과에서_전환하면_플로빙_기록_안내로_넘어간다() async {
        let store = makeStore(step: .recordResult, recordType: .plogging)

        await store.send(.tutorialActivitySwitched)

        #expect(store.state.tutorialRecordType == .plobbing)
        #expect(store.state.tutorialStep == .recordIntro)
    }

    @Test
    func 플로깅_기록_결과가_아니면_전환을_무시한다() async {
        let store = makeStore(step: .scroll, recordType: .plogging)

        await store.send(.tutorialActivitySwitched)

        #expect(store.state.tutorialRecordType == .plogging)
        #expect(store.state.tutorialStep == .scroll)
    }

    @Test
    func 플로빙_기록_결과에서는_전환하지_않고_다음은_마무리다() async {
        let store = makeStore(step: .recordResult, recordType: .plobbing)

        await store.send(.tutorialActivitySwitched)
        #expect(store.state.tutorialStep == .recordResult)

        await store.send(.tutorialAdvanced)
        #expect(store.state.tutorialStep == .finish)
    }

    // MARK: - 마무리

    @Test
    func 끝까지_보면_대기가_꺼지고_다시_들어와도_뜨지_않는다() async {
        @Shared(.isHomeTutorialPending) var isHomeTutorialPending = false
        $isHomeTutorialPending.withLock { $0 = true }
        let store = makeStore(step: .finish, recordType: .plobbing)

        await store.send(.tutorialFinished)
        #expect(store.state.tutorialStep == nil)
        #expect(!isHomeTutorialPending)

        await store.send(.onAppear)
        #expect(store.state.tutorialStep == nil)
    }
}

// MARK: - Helpers

private extension HomeTutorialFeatureTests {

    func makeStore(
        step: HomeTutorialStep? = nil,
        recordType: RecordType = .plogging,
        clock: any Clock<Duration> = ImmediateClock()
    ) -> TestStoreOf<HomeFeature> {
        var state = HomeFeature.State()
        state.tutorialStep = step
        state.tutorialRecordType = recordType

        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.date.now = GoalFixture.now
            $0.calendar = GoalFixture.calendar
            $0.continuousClock = clock
            $0.goalClient = GoalClient(
                fetchCurrentGoal: { _ in nil },
                fetchGoals: { _ in [Goal.fixture()] },
                fetchUpcomingGoal: { _ in nil },
                fetchDailyProgresses: { _, _ in [] },
                fetchTrashSummaries: { _, _ in [] },
                fetchParticipants: { _, _ in [] },
                fetchGoalRecords: { _ in [] }
            )
        }
        store.exhaustivity = .off
        return store
    }
}
