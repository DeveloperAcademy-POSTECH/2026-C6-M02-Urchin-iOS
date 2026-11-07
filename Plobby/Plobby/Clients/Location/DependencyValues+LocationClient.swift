//
//  DependencyValues+LocationClient.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import Dependencies

extension DependencyValues {

    var locationClient: LocationClient {
        get { self[LocationClient.self] }
        set { self[LocationClient.self] = newValue }
    }
}
