//
//  ToastFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/5/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
struct ToastFeatureTests {

    @Test
    func 토스트를_띄우면_잠시_뒤_사라진다() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.show(.photoSaveFailed)) {
            $0.toastType = .photoSaveFailed
        }
        await clock.advance(by: ToastFeature.toastDuration)
        await store.receive(\.toastDismissed) {
            $0.toastType = nil
        }
    }

    @Test
    func 연달아_띄우면_마지막_토스트부터_다시_센다() async {
        let clock = TestClock()
        let store = makeStore(clock: clock)

        await store.send(.show(.photoLimitExceeded)) {
            $0.toastType = .photoLimitExceeded
        }
        await clock.advance(by: .seconds(1))
        await store.send(.show(.photoSaveFailed)) {
            $0.toastType = .photoSaveFailed
        }

        // 첫 번째 타이머가 끝날 시점에는 사라지지 않아요.
        await clock.advance(by: .seconds(1))
        await clock.advance(by: .seconds(1))
        await store.receive(\.toastDismissed) {
            $0.toastType = nil
        }
    }

    // MARK: - Helpers

    private func makeStore(clock: TestClock<Duration>) -> TestStoreOf<ToastFeature> {
        TestStore(initialState: ToastFeature.State()) {
            ToastFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
    }
}
