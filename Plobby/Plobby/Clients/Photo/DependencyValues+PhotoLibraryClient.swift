//
//  DependencyValues+PhotoLibraryClient.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import Dependencies

extension DependencyValues {

    var photoLibraryClient: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
