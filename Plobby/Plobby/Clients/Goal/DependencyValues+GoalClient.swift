//
//  DependencyValues+GoalClient.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Dependencies

extension DependencyValues {

    var goalClient: GoalClient {
        get { self[GoalClient.self] }
        set { self[GoalClient.self] = newValue }
    }
}
