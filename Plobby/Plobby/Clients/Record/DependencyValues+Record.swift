//
//  DependencyValues+Record.swift
//  Plobby
//
//  Created by 더스틴 on 11/2/26.
//

import Dependencies

extension DependencyValues {
    
    nonisolated var recordClient: RecordClient {
        get { self[RecordClient.self] }
        set { self[RecordClient.self] = newValue }
    }
}
