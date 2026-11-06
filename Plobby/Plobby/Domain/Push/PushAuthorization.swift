//
//  PushAuthorization.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

/// iOS 알림 권한 상태
nonisolated enum PushAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
}
