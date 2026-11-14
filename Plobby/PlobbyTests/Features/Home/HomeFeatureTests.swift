//
//  HomeFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/13/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

/// 공통 목표가 달성되거나 끝나거나 바뀔 때 홈이 어떻게 보이는지 확인해요.
@MainActor
struct HomeFeatureTests {

    private let now = GoalFixture.now

    private let days = [
        GoalDailyProgress(day: GoalFixture.day(-2), collectedCount: 4, participantCount: 1),
        GoalDailyProgress(day: GoalFixture.day(-1), collectedCount: 3, participantCount: 2),
        GoalDailyProgress(day: GoalFixture.day(0), collectedCount: 3, participantCount: 1)
    ]

    // MARK: - 달성·종료

    @Test
    func 기간이_남은_달성_목표는_끝난_화면으로_보여준다() async {
        let store = makeStore(goals: [Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])

        await load(store)

        #expect(store.state.status == .achieved)
        #expect(store.state.isGoalFinished)
        #expect(store.state.isWalkLocked)
        #expect(!store.state.isScrollGuideVisible)
        for type in RecordType.allCases {
            #expect(store.state.stages[type] == .finale(step: type.resultStep))
            #expect(store.state.walkProgresses[type] == Double(days.count))
        }
    }

    @Test
    func 미달성으로_기간이_끝난_목표는_기간_종료로_보여준다() async {
        let ended = Goal.fixture(startsAt: GoalFixture.day(-10), endsAt: GoalFixture.day(-1))
        let store = makeStore(goals: [ended])

        await load(store)

        #expect(store.state.board?.goal.id == ended.id)
        #expect(store.state.status == .ended)
        #expect(store.state.isGoalFinished)
    }

    @Test
    func 끝난_목표에서는_화면을_내려도_장면이_바뀌지_않는다() async {
        let store = makeStore(goals: [Goal.fixture(achievedAt: GoalFixture.hours(-1))])
        await load(store)
        let stage = store.state.stage
        let walkProgress = store.state.walkProgress

        await store.send(.sceneWalked(to: 0))

        #expect(store.state.stage == stage)
        #expect(store.state.walkProgress == walkProgress)
        #expect(store.state.transitioningTypes.isEmpty)
    }

    /// 다른 사람이 마지막 개수를 채운 뒤 홈에 다시 들어오면 달성 화면으로 바뀌어야 해요.
    @Test
    func 진행_중이던_목표가_달성된_뒤_다시_들어오면_끝난_화면으로_바뀐다() async {
        let goal = Goal.fixture(collectedCount: 999)
        let goals = LockIsolated([goal])
        let store = makeStore(goals: goals)
        await load(store)
        #expect(store.state.status == .inProgress(remainingDays: 6))

        goals.setValue([Goal.fixture(id: goal.id, achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])
        await load(store)

        #expect(store.state.status == .achieved)
        #expect(store.state.stage == .finale(step: RecordType.plogging.resultStep))
    }

    // MARK: - 다음 목표로 넘어가기

    @Test
    func 다음_목표가_시작되면_새_목표_기준으로_다시_그린다() async {
        let achieved = Goal.fixture(startsAt: GoalFixture.day(-20), endsAt: GoalFixture.day(-1), achievedAt: GoalFixture.day(-3))
        let next = Goal.fixture(startsAt: GoalFixture.day(0), endsAt: GoalFixture.day(30), collectedCount: 5)
        let goals = LockIsolated([achieved])
        let store = makeStore(goals: goals)
        await load(store)
        #expect(store.state.status == .achieved)

        goals.setValue([next, achieved])
        await tapNextGoal(store)

        #expect(store.state.board?.goal.id == next.id)
        #expect(store.state.status == .inProgress(remainingDays: 29))
        #expect(!store.state.isGoalFinished)
        #expect(!store.state.isWalkLocked)
        #expect(store.state.stage == .arrived(day: days.count - 1))
        #expect(store.state.walkProgress == Double(days.count - 1))
    }

    /// 서버가 달성 순간에 다음 목표를 시작시켜도, 홈은 "다음 목표 보기"를 누를 때까지 달성한 목표와 축하를 보여줘요.
    @Test
    func 다음_목표가_달성_순간에_시작해도_다음_목표_보기_전까지는_달성_목표를_보여준다() async {
        let achieved = Goal.fixture(endsAt: GoalFixture.hours(-1), achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let next = Goal.fixture(startsAt: GoalFixture.hours(-1), endsAt: GoalFixture.day(30), collectedCount: 0)
        let store = makeStore(goals: [next, achieved])

        await load(store)
        await load(store)

        #expect(store.state.board?.goal.id == achieved.id)
        #expect(store.state.isCelebrationVisible)
    }

    @Test
    func 다음_목표_보기를_누르면_달성_순간에_시작한_다음_목표로_바뀐다() async {
        let achieved = Goal.fixture(endsAt: GoalFixture.hours(-1), achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let next = Goal.fixture(startsAt: GoalFixture.hours(-1), endsAt: GoalFixture.day(30), collectedCount: 0)
        let store = makeStore(goals: [next, achieved])
        await load(store)

        await tapNextGoal(store)

        #expect(store.state.board?.goal.id == next.id)
        #expect(store.state.status == .inProgress(remainingDays: 29))
        #expect(!store.state.isCelebrationVisible)
        #expect(store.state.isGoalExpanded)
    }

    /// 다음 목표는 아직 모은 쓰레기가 없으니 카드를 펼쳐 기록하기 버튼이 보여야 해요.
    @Test
    func 다음_목표의_쓰레기가_0개면_카드를_펼친다() async {
        let goals = LockIsolated([Goal.fixture(collectedCount: 10)])
        let store = makeStore(goals: goals)
        await load(store)
        #expect(!store.state.isGoalExpanded)

        goals.setValue([Goal.fixture(startsAt: GoalFixture.day(0), endsAt: GoalFixture.day(30), collectedCount: 0)])
        await load(store)

        #expect(store.state.isGoalExpanded)
    }

    @Test
    func 같은_목표에_다시_들어오면_카드는_접힌_채로_둔다() async {
        let store = makeStore(goals: [Goal.fixture(collectedCount: 0)])
        await load(store)
        #expect(store.state.isGoalExpanded)

        await load(store)

        #expect(!store.state.isGoalExpanded)
    }

    // MARK: - 축하

    @Test
    func 달성한_목표를_보면_축하한다() async {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let store = makeStore(goals: [goal])

        await load(store)

        #expect(store.state.isCelebrationVisible)
        #expect(!store.state.dismissedGoalKeys.contains(goal.dismissalKey))
    }

    @Test
    func 다음_목표_보기를_누르기_전에는_다시_들어와도_계속_축하한다() async {
        let store = makeStore(goals: [Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])
        await load(store)
        #expect(store.state.isCelebrationVisible)

        await load(store)
        await load(store)

        #expect(store.state.isCelebrationVisible)
    }

    @Test
    func 다음_목표_보기를_누르면_축하를_끈다() async {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let store = makeStore(goals: [goal])
        await load(store)

        await tapNextGoal(store)

        #expect(!store.state.isCelebrationVisible)
        #expect(store.state.dismissedGoalKeys.contains(goal.dismissalKey))
        #expect(store.state.goalList == nil)
    }

    @Test
    func 다음_목표_보기를_누른_목표는_다시_들어와도_축하하지_않는다() async {
        let store = makeStore(goals: [Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])
        await load(store)
        await tapNextGoal(store)

        await load(store)

        #expect(!store.state.isCelebrationVisible)
        #expect(store.state.isGoalFinished)
    }

    @Test
    func 기간_종료도_다음_목표_보기를_누를_때까지_보여준다() async {
        let store = makeStore(goals: [Goal.fixture(startsAt: GoalFixture.day(-10), endsAt: GoalFixture.day(-1))])
        await load(store)
        await load(store)
        #expect(store.state.isCelebrationVisible)

        await tapNextGoal(store)

        #expect(!store.state.isCelebrationVisible)
    }

    /// 진행 중일 때 같은 버튼은 "목표 전체 보기"라서 축하 기록을 남기지 않아요.
    @Test
    func 진행_중에_목표_전체_보기를_눌러도_나중에_달성하면_축하한다() async {
        let goal = Goal.fixture(collectedCount: 999)
        let goals = LockIsolated([goal])
        let store = makeStore(goals: goals)
        await load(store)

        await store.send(.allGoalsButtonTapped)
        #expect(!store.state.dismissedGoalKeys.contains(goal.dismissalKey))

        goals.setValue([Goal.fixture(id: goal.id, achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])
        await load(store)

        #expect(store.state.isCelebrationVisible)
    }

    @Test
    func 진행_중인_목표는_축하하지_않는다() async {
        let goal = Goal.fixture()
        let store = makeStore(goals: [goal])

        await load(store)

        #expect(!store.state.isCelebrationVisible)
        #expect(!store.state.dismissedGoalKeys.contains(goal.dismissalKey))
    }

    /// 진행 중이던 목표가 달성된 뒤 들어오면 그때 처음 축하해요.
    @Test
    func 진행_중이던_목표가_달성되면_그때_축하한다() async {
        let goal = Goal.fixture(collectedCount: 999)
        let goals = LockIsolated([goal])
        let store = makeStore(goals: goals)
        await load(store)
        #expect(!store.state.isCelebrationVisible)

        goals.setValue([Goal.fixture(id: goal.id, achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])
        await load(store)

        #expect(store.state.isCelebrationVisible)
    }

    @Test
    func 다른_목표가_끝나면_다시_축하한다() async {
        let first = Goal.fixture(startsAt: GoalFixture.day(-20), endsAt: GoalFixture.day(-10), achievedAt: GoalFixture.day(-12))
        let second = Goal.fixture(startsAt: GoalFixture.day(-9), endsAt: GoalFixture.day(-1), achievedAt: GoalFixture.day(-2))
        let goals = LockIsolated([first])
        let store = makeStore(goals: goals)
        await load(store)
        await tapNextGoal(store)
        #expect(!store.state.isCelebrationVisible)

        goals.setValue([second, first])
        await load(store)

        #expect(store.state.board?.goal.id == second.id)
        #expect(store.state.isCelebrationVisible)
    }

    /// QA에서 달성을 되돌렸다가 같은 목표를 다시 달성시켜도 축하가 다시 나와야 해요.
    @Test
    func 넘긴_목표가_다시_달성되면_다시_축하한다() async {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-3), collectedCount: 1_000)
        let goals = LockIsolated([goal])
        let store = makeStore(goals: goals)
        await load(store)
        await tapNextGoal(store)
        #expect(!store.state.isCelebrationVisible)

        goals.setValue([Goal.fixture(id: goal.id, achievedAt: GoalFixture.hours(-1), collectedCount: 1_030)])
        await load(store)

        #expect(store.state.isCelebrationVisible)
    }

    // MARK: - 다음 목표 보기

    @Test
    func 다음_목표_보기는_목표_목록을_열지_않는다() async {
        let store = makeStore(goals: [Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)])
        await load(store)

        await tapNextGoal(store)

        #expect(store.state.goalList == nil)
    }

    @Test
    func 다음_목표_보기를_누르면_시작_전인_다음_목표를_불러온다() async {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let upcoming = Goal.fixture(startsAt: GoalFixture.day(1), endsAt: GoalFixture.day(30), collectedCount: 0)
        let store = makeStore(goals: [achieved], upcoming: upcoming)
        await load(store)
        #expect(store.state.board?.goal.id == achieved.id)

        await tapNextGoal(store)

        #expect(store.state.board?.goal.id == upcoming.id)
        #expect(store.state.status == .upcoming(daysUntilStart: 1))
        #expect(!store.state.isGoalFinished)
        #expect(!store.state.isCelebrationVisible)
        #expect(store.state.isGoalExpanded)
    }

    @Test
    func 다음_목표로_넘긴_뒤_다시_들어와도_다음_목표를_보여준다() async {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let upcoming = Goal.fixture(startsAt: GoalFixture.day(1), endsAt: GoalFixture.day(30), collectedCount: 0)
        let store = makeStore(goals: [achieved], upcoming: upcoming)
        await load(store)
        await tapNextGoal(store)

        await load(store)

        #expect(store.state.board?.goal.id == upcoming.id)
    }

    /// 넘긴 목표는 다시 들어와도 건너뛰고 진행 중인 목표를 보여줘요.
    @Test
    func 넘긴_달성_목표는_다시_들어와도_진행_중인_목표를_보여준다() async {
        let achieved = Goal.fixture(startsAt: GoalFixture.day(-20), endsAt: GoalFixture.day(-1), achievedAt: GoalFixture.day(-3))
        let next = Goal.fixture(startsAt: GoalFixture.day(0), endsAt: GoalFixture.day(30), collectedCount: 0)
        let store = makeStore(goals: [next, achieved])
        await load(store)
        await tapNextGoal(store)

        await load(store)

        #expect(store.state.board?.goal.id == next.id)
    }

    @Test
    func 다음_목표가_없으면_끝난_목표를_그대로_보여준다() async {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_000)
        let store = makeStore(goals: [achieved])
        await load(store)

        await tapNextGoal(store)

        #expect(store.state.board?.goal.id == achieved.id)
        #expect(store.state.isGoalFinished)
        #expect(!store.state.isCelebrationVisible)
    }

    @Test
    func 진행_중인_목표에서는_다음_목표_보기가_아무것도_하지_않는다() async {
        let goal = Goal.fixture()
        let store = makeStore(goals: [goal])
        await load(store)

        await store.send(.nextGoalButtonTapped)

        #expect(!store.state.dismissedGoalKeys.contains(goal.dismissalKey))
        #expect(store.state.board?.goal.id == goal.id)
    }

    @Test
    func 목표_전체_보기는_목표_목록을_연다() async {
        let store = makeStore(goals: [Goal.fixture()])
        await load(store)

        await store.send(.allGoalsButtonTapped)

        #expect(store.state.goalList != nil)
    }

    // MARK: - 목표가 없거나 불러오지 못할 때

    @Test
    func 목표가_하나도_없으면_끝난_화면으로_보지_않는다() async {
        let store = makeStore(goals: [])

        await load(store)

        #expect(store.state.boards.isEmpty)
        #expect(store.state.status == nil)
        #expect(!store.state.isGoalFinished)
        #expect(!store.state.isWalkLocked)
        #expect(!store.state.isCelebrationVisible)
    }

    @Test
    func 목표를_불러오지_못하면_보던_목표를_그대로_둔다() async {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-1))
        let store = makeStore(goals: [goal])
        await load(store)

        await store.send(.boardsResponse(.failure(TestError()), now: now))

        #expect(store.state.board?.goal.id == goal.id)
        #expect(store.state.status == .achieved)
    }
}

// MARK: - Helpers

private extension HomeFeatureTests {

    struct TestError: Error {}

    func makeStore(goals: [Goal], upcoming: Goal? = nil) -> TestStoreOf<HomeFeature> {
        makeStore(goals: LockIsolated(goals), upcoming: upcoming)
    }

    func makeStore(goals: LockIsolated<[Goal]>, upcoming: Goal? = nil) -> TestStoreOf<HomeFeature> {
        let days = days
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.date.now = now
            $0.calendar = GoalFixture.calendar
            $0.continuousClock = ImmediateClock()
            $0.goalClient = GoalClient(
                fetchCurrentGoal: { _ in
                    Issue.record("홈은 목표 목록에서 직접 골라요")
                    return nil
                },
                fetchGoals: { _ in goals.value },
                fetchUpcomingGoal: { _ in upcoming },
                fetchDailyProgresses: { _, _ in days },
                fetchTrashSummaries: { _, _ in [GoalTrashSummary(category: .plastic, collectedCount: 10)] },
                fetchParticipants: { _, _ in [] },
                fetchGoalRecords: { _ in [] }
            )
        }
        store.exhaustivity = .off
        return store
    }

    func load(_ store: TestStoreOf<HomeFeature>) async {
        await store.send(.onAppear)
        await store.receive(\.boardsResponse)
    }

    /// "다음 목표 보기"를 누르면 홈을 다시 불러와요.
    func tapNextGoal(_ store: TestStoreOf<HomeFeature>) async {
        await store.send(.nextGoalButtonTapped)
        await store.receive(\.boardsResponse)
    }
}
