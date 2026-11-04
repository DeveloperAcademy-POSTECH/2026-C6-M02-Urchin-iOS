//
//  DatePickerFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/4/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
struct DatePickerFeatureTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    @Test
    func 달력은_일요일부터_시작하고_빈_칸으로_주를_채운다() {
        // 2026년 10월 1일은 목요일
        let days = DatePickerFeature.days(in: date(2026, 10, 1), calendar: calendar)

        #expect(days.count == 35)
        #expect(days.prefix(4).allSatisfy { $0 == nil })
        #expect(days[4] == date(2026, 10, 1))
        #expect(days[34] == date(2026, 10, 31))
    }

    @Test
    func 이전_달로_갔다가_다음_달로_돌아온다() async {
        let store = makeStore(date: date(2026, 10, 23))

        await store.send(.previousMonthTapped) {
            $0.month = self.date(2026, 9, 1)
            $0.days = DatePickerFeature.days(in: self.date(2026, 9, 1), calendar: self.calendar)
            $0.isNextMonthEnabled = true
        }
        await store.send(.nextMonthTapped) {
            $0.month = self.date(2026, 10, 1)
            $0.days = DatePickerFeature.days(in: self.date(2026, 10, 1), calendar: self.calendar)
            $0.isNextMonthEnabled = false
        }
    }

    @Test
    func 이번_달에서는_다음_달로_이동할_수_없다() async {
        let store = makeStore(date: date(2026, 10, 23))

        await store.send(.nextMonthTapped)
    }

    @Test
    func 오늘_이후_날짜는_선택할_수_없다() async {
        let store = makeStore(date: date(2026, 10, 23))

        await store.send(.dayTapped(date(2026, 10, 24)))
    }

    @Test
    func 날짜를_선택하면_기존_시각을_유지한다() async {
        let store = makeStore(date: date(2026, 10, 23, hour: 14, minute: 30))

        await store.send(.dayTapped(date(2026, 10, 20))) {
            $0.date = self.date(2026, 10, 20, hour: 14, minute: 30)
        }
        await store.send(.confirmTapped)
        await store.receive(\.delegate.confirmed)
    }
    // MARK: - Helpers

    private func makeStore(date: Date) -> TestStoreOf<DatePickerFeature> {
        TestStore(
            initialState: DatePickerFeature.State(
                field: .end,
                date: date,
                today: date,
                calendar: calendar
            )
        ) {
            DatePickerFeature()
        } withDependencies: {
            $0.calendar = calendar
        }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
