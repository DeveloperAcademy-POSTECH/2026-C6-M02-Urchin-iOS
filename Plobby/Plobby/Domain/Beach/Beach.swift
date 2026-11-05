//
//  Beach.swift
//  Plobby
//
//  Created by 이은지 on 11/1/26.
//

import Foundation

nonisolated struct Beach: Identifiable, Equatable, Sendable {
    let id: UUID
    let region: Sea
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}
