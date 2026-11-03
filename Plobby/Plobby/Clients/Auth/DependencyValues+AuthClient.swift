//
//  DependencyValues+.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Dependencies

extension DependencyValues {
    
    nonisolated var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
