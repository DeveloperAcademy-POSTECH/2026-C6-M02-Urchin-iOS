//
//  PushEvents.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Foundation

// AppDelegate → PushClient 통로. 구독 전에 들어온 값을 잃지 않도록 마지막 값 1개를 보관
nonisolated enum PushEvents {
    static let tokenStream = AsyncStream.makeStream(
        of: String.self,
        bufferingPolicy: .bufferingNewest(1)
    )
    static let tappedRecordIDStream = AsyncStream.makeStream(
        of: UUID.self,
        bufferingPolicy: .bufferingNewest(1)
    )
}
