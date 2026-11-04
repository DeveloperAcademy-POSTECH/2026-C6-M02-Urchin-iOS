//
//  DependencyValues+PushClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Dependencies

extension DependencyValues {
    var pushClient: PushClient {
        get { self[PushClient.self] }
        set { self[PushClient.self] = newValue }
    }
}
