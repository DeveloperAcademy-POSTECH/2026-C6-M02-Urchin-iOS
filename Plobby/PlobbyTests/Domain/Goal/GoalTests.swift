//
//  GoalTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/13/26.
//

import Foundation
import Testing
@testable import Plobby

/// 공통 목표의 상태(진행 중·달성·기간 종료), D-day, 진행도를 확인해요.
struct GoalTests {

    private let now = GoalFixture.now

    // MARK: - 상태

    @Test
    func 기간_안에_달성하면_남은_기간과_상관없이_달성이다() {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-1))

        #expect(goal.status(at: now) == .achieved)
        #expect(goal.homeStatus(at: now) == .achieved)
        #expect(goal.homeStatus(at: now).isFinished)
    }

    @Test
    func 기간이_끝난_뒤에도_달성_기록이_있으면_달성이다() {
        let goal = Goal.fixture(endsAt: GoalFixture.day(-1), achievedAt: GoalFixture.day(-3))

        #expect(goal.status(at: now) == .achieved)
    }

    @Test
    func 미달성이고_종료_전이면_진행_중이다() {
        let goal = Goal.fixture()

        #expect(goal.status(at: now) == .inProgress)
        #expect(!goal.homeStatus(at: now).isFinished)
    }

    @Test
    func 미달성으로_기간이_끝나면_기간_종료다() {
        let goal = Goal.fixture(endsAt: GoalFixture.day(-1))

        #expect(goal.status(at: now) == .ended)
        #expect(goal.homeStatus(at: now) == .ended)
    }

    @Test
    func 종료_시각과_같은_순간부터_기간_종료다() {
        let goal = Goal.fixture(endsAt: now)

        #expect(goal.status(at: now) == .ended)
        #expect(goal.status(at: now.addingTimeInterval(-1)) == .inProgress)
    }

    /// 서버가 달성 시각을 채우기 전에는 개수를 다 채워도 진행 중으로 보여요.
    /// 기록 직후 홈에 돌아왔을 때 "1,000 / 1,000개"인데 D-day가 보일 수 있어요.
    @Test
    func 목표_개수를_채워도_달성_시각이_없으면_진행_중이다() {
        let goal = Goal.fixture(collectedCount: 1_000)

        #expect(goal.status(at: now) == .inProgress)
    }

    /// 달성 뒤 기록이 지워져 개수가 줄어도 달성은 유지돼요.
    @Test
    func 달성_후_개수가_목표보다_적어져도_달성이다() {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 990)

        #expect(goal.status(at: now) == .achieved)
    }

    // MARK: - D-day

    @Test
    func 종료_시각이_자정이면_마지막_날은_그_전날이다() {
        let goal = Goal.fixture(endsAt: GoalFixture.day(7))

        #expect(goal.lastDay == GoalFixture.day(6))
    }

    @Test
    func 마지막_날에는_D_Day다() {
        let goal = Goal.fixture(endsAt: GoalFixture.day(1))

        #expect(goal.homeStatus(at: now) == .inProgress(remainingDays: 0))
        #expect(goal.homeStatus(at: now).chipText == "D-Day")
    }

    @Test
    func 마지막_날_자정_직전까지_D_Day이고_자정이_되면_기간_종료다() {
        let goal = Goal.fixture(endsAt: GoalFixture.day(1))
        let justBeforeMidnight = GoalFixture.day(1).addingTimeInterval(-1)

        #expect(goal.homeStatus(at: justBeforeMidnight) == .inProgress(remainingDays: 0))
        #expect(goal.homeStatus(at: GoalFixture.day(1)) == .ended)
    }

    // MARK: - 진행도

    @Test
    func 목표를_넘게_모아도_진행도는_1이다() {
        let goal = Goal.fixture(achievedAt: GoalFixture.hours(-1), collectedCount: 1_200)

        #expect(goal.progress == 1)
    }

    /// 목표 개수가 0으로 잘못 들어와도 0 ÷ 0으로 NaN이 되지 않아야 진행 막대가 깨지지 않아요.
    @Test
    func 목표_개수가_0이면_진행도는_0이다() {
        let goal = Goal.fixture(targetCount: 0, collectedCount: 0)

        #expect(goal.progress == 0)
    }

    // MARK: - 홈 목표 고르기

    @Test
    func 넘기지_않은_달성_목표는_진행_중인_다음_목표보다_먼저_고른다() {
        let achieved = Goal.fixture(endsAt: GoalFixture.hours(-1), achievedAt: GoalFixture.hours(-1))
        let next = Goal.fixture(startsAt: GoalFixture.hours(-1), endsAt: GoalFixture.day(30))

        #expect(Goal.homeGoal(in: [achieved, next], at: now)?.id == achieved.id)
        #expect(Goal.homeGoal(in: [next, achieved], at: now)?.id == achieved.id)
    }

    @Test
    func 달성_목표를_넘기면_진행_중인_다음_목표를_고른다() {
        let achieved = Goal.fixture(endsAt: GoalFixture.hours(-1), achievedAt: GoalFixture.hours(-1))
        let next = Goal.fixture(startsAt: GoalFixture.hours(-1), endsAt: GoalFixture.day(30))

        #expect(Goal.homeGoal(in: [achieved, next], skipping: [achieved.dismissalKey], at: now)?.id == next.id)
    }

    @Test
    func 진행_중인_목표가_여러_개면_가장_최근에_시작한_목표를_고른다() {
        let older = Goal.fixture(startsAt: GoalFixture.day(-5))
        let newer = Goal.fixture(startsAt: GoalFixture.day(-1))

        #expect(Goal.homeGoal(in: [older, newer], at: now)?.id == newer.id)
    }

    @Test
    func 진행_중인_목표가_없으면_가장_최근에_시작한_목표를_고른다() {
        let older = Goal.fixture(startsAt: GoalFixture.day(-30), endsAt: GoalFixture.day(-20))
        let newer = Goal.fixture(startsAt: GoalFixture.day(-10), endsAt: GoalFixture.day(-1), achievedAt: GoalFixture.day(-3))

        #expect(Goal.homeGoal(in: [older, newer], at: now)?.id == newer.id)
    }

    @Test
    func 아직_시작하지_않은_목표는_고르지_않는다() {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-2))
        let upcoming = Goal.fixture(startsAt: GoalFixture.day(1), endsAt: GoalFixture.day(30))

        #expect(Goal.homeGoal(in: [upcoming, achieved], at: now)?.id == achieved.id)
    }

    @Test
    func 넘긴_끝난_목표_대신_시작_전인_다음_목표를_고른다() {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-1))
        let upcoming = Goal.fixture(startsAt: GoalFixture.day(1), endsAt: GoalFixture.day(30))

        #expect(Goal.homeGoal(in: [achieved], upcoming: upcoming, at: now)?.id == achieved.id)
        #expect(Goal.homeGoal(in: [achieved], upcoming: upcoming, skipping: [achieved.dismissalKey], at: now)?.id == upcoming.id)
    }

    @Test
    func 다음_목표가_없으면_넘긴_목표라도_끝난_목표를_고른다() {
        let achieved = Goal.fixture(achievedAt: GoalFixture.hours(-1))

        #expect(Goal.homeGoal(in: [achieved], skipping: [achieved.dismissalKey], at: now)?.id == achieved.id)
    }

    @Test
    func 시작_전인_목표는_시작까지_남은_날을_보여준다() {
        let goal = Goal.fixture(startsAt: GoalFixture.day(3), endsAt: GoalFixture.day(30))

        #expect(goal.homeStatus(at: now) == .upcoming(daysUntilStart: 3))
        #expect(goal.homeStatus(at: now).chipText == "3일 뒤 시작")
        #expect(!goal.homeStatus(at: now).isFinished)
    }

    @Test
    func 오늘_시작하는_목표는_오늘_시작이다() {
        let goal = Goal.fixture(startsAt: GoalFixture.hours(2), endsAt: GoalFixture.day(30))

        #expect(goal.homeStatus(at: now).chipText == "오늘 시작")
    }

    @Test
    func 목표가_없으면_고르지_않는다() {
        #expect(Goal.homeGoal(in: [], at: now) == nil)
    }
}
