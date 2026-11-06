//
//  BeachMarker.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

nonisolated struct BeachMarker: Equatable, Identifiable, Sendable {

    let beach: Beach
    let recordCount: Int

    var id: UUID { beach.id }
}
