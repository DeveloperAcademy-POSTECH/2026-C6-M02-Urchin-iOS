//
//  TimePickerFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/4/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
struct TimePickerFeatureTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    // MARK: - 초기 값

    @Test
    func 기존_시각으로_휠의_초기_값을_정한다() {
        let time = makeState(date: date(hour: 18, minute: 5)).selectedTime

        #expect(time.meridiem == .pm)
        #expect(time.hour12 == 6)
        #expect(time.minute == 5)
    }

    @Test
    func 자정과_정오는_12시로_표시한다() {
        let midnight = makeState(field: .start, date: date(hour: 0, minute: 0)).selectedTime
        let noon = makeState(field: .start, date: date(hour: 12, minute: 0)).selectedTime

        #expect(midnight.meridiem == .am && midnight.hour12 == 12)
        #expect(noon.meridiem == .pm && noon.hour12 == 12)
    }

    // MARK: - 스크롤과 완료

    @Test
    func 휠을_스크롤하고_완료하면_선택한_시각을_전달한다() async {
        let store = makeStore(date: date(hour: 9, minute: 0))
        let hourRow = store.state.hourWheel.row
        let minuteRow = store.state.minuteWheel.row

        await store.send(.wheelScrolled(.meridiem, row: 1)) {
            $0.meridiemWheel.row = 1
        }
        await store.send(.wheelScrolled(.hour, row: hourRow + 1)) {
            $0.hourWheel.row = hourRow + 1
        }
        await store.send(.wheelScrolled(.minute, row: minuteRow - 1)) {
            $0.minuteWheel.row = minuteRow - 1
        }
        await store.send(.confirmTapped)
        await store.receive(\.delegate.confirmed)

        #expect(store.state.selectedTime == TimeOfDay(hour24: 22, minute: 59))
    }

    // MARK: - 오늘의 종료 시간 제한

    @Test
    func 오늘의_종료_시간은_현재_시각까지만_휠에_올린다() {
        let state = makeState(date: date(hour: 11, minute: 30), now: date(hour: 11, minute: 40))

        #expect(state.meridiemWheel.values == [.am])
        #expect(state.hourWheel.values == [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        #expect(state.hourWheel.isCyclic == false)
        #expect(state.minuteWheel.values == Array(0...40))
        #expect(state.minuteWheel.isCyclic == false)
    }

    @Test
    func 현재보다_이른_시를_고르면_분_휠은_다시_순환한다() async {
        let store = makeStore(date: date(hour: 11, minute: 30), now: date(hour: 11, minute: 40))
        store.exhaustivity = .off

        await store.send(.wheelScrolled(.hour, row: store.state.hourWheel.row - 1))

        #expect(store.state.selectedTime == TimeOfDay(hour24: 10, minute: 30))
        #expect(store.state.minuteWheel.isCyclic)
        #expect(store.state.minuteWheel.values == Array(0...59))
    }

    @Test
    func 다시_현재_시로_돌아오면_늦은_분은_현재_분으로_맞춘다() async {
        let store = makeStore(date: date(hour: 10, minute: 50), now: date(hour: 11, minute: 40))
        store.exhaustivity = .off

        await store.send(.wheelScrolled(.hour, row: store.state.hourWheel.row + 1))

        #expect(store.state.selectedTime == TimeOfDay(hour24: 11, minute: 40))
        #expect(store.state.minuteWheel.values == Array(0...40))
    }

    @Test
    func 현재보다_늦은_기존_시각은_현재_시각으로_시작한다() {
        let state = makeState(date: date(hour: 15, minute: 0), now: date(hour: 11, minute: 40))

        #expect(state.selectedTime == TimeOfDay(hour24: 11, minute: 40))
    }

    @Test
    func 지난_날의_종료_시간과_시작_시간은_제한하지_않는다() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date(hour: 11, minute: 30))!
        let pastEnd = makeState(date: yesterday, now: date(hour: 11, minute: 40))
        let start = makeState(field: .start, date: date(hour: 11, minute: 30), now: date(hour: 11, minute: 40))

        for state in [pastEnd, start] {
            #expect(state.meridiemWheel.values == [.am, .pm])
            #expect(state.hourWheel.isCyclic)
            #expect(state.minuteWheel.isCyclic)
        }
    }
}

// MARK: - Helpers

extension TimePickerFeatureTests {

    private func makeState(
        field: PeriodField = .end,
        date: Date,
        now: Date? = nil
    ) -> TimePickerFeature.State {
        let now = now ?? calendar.date(byAdding: .day, value: 1, to: date)!

        return TimePickerFeature.State(
            field: field,
            date: date,
            allowedRange: field == .end ? Date.distantPast...now : Date.distantPast...Date.distantFuture,
            calendar: calendar
        )
    }

    private func makeStore(date: Date, now: Date? = nil) -> TestStoreOf<TimePickerFeature> {
        TestStore(initialState: makeState(date: date, now: now)) {
            TimePickerFeature()
        } withDependencies: {
            $0.calendar = calendar
        }
    }

    private func date(hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: hour, minute: minute))!
    }
}
