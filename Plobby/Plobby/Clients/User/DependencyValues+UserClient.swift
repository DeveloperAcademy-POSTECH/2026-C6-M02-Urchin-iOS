//
//  DependencyValues+UserClient.swift
//  Plobby
//
//  Created by dlsundn on 11/3/26.
//

import Dependencies

extension DependencyValues {
    var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}
