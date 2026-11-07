//
//  Effect+.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

extension Effect {

    /// interval마다 action을 보내는 타이머
    /// 같은 id로 다시 시작하면 이전 타이머 취소
    static func timer(
        id: some Hashable & Sendable,
        interval: Duration,
        action: Action,
        animation: Animation? = nil
    ) -> Self {
        .run { send in
            @Dependency(\.continuousClock) var clock

            for await _ in clock.timer(interval: interval) {
                await send(action, animation: animation)
            }
        }
        .cancellable(id: id, cancelInFlight: true)
    }
}
