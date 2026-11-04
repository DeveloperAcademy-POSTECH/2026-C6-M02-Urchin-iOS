//
//  PhotoAuthorization.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

nonisolated enum PhotoAuthorization: Equatable, Sendable {
    
    case notDetermined
    case authorized
    case limited
    case denied
}

extension PhotoAuthorization {
    
    var canReadLibrary: Bool {
        self == .authorized || self == .limited
    }
}
