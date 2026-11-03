//
//  DependencyValues+BeachClient.swift
//  Plobby
//
//  Created by 이은지 on 11/3/26.
//

import Dependencies

extension DependencyValues {

    var beachClient: BeachClient {
        get { self[BeachClient.self] }
        set { self[BeachClient.self] = newValue }
    }
}
