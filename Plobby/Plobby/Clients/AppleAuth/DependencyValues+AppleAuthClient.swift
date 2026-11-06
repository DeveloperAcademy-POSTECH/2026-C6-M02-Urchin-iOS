//
//  DependencyValues+AppleAuthClient.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import Dependencies

extension DependencyValues {

    var appleAuthClient: AppleAuthClient {
        get { self[AppleAuthClient.self] }
        set { self[AppleAuthClient.self] = newValue }
    }
}
