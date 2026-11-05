//
//  PlaceSeaerchResult.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import CoreLocation

nonisolated struct PlaceSearchResult: Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: Coordinate
}

nonisolated extension PlaceSearchResult {

    init(beach: Beach) {
        self.init(
            id: beach.id,
            name: beach.name,
            address: beach.address,
            coordinate: Coordinate(latitude: beach.latitude, longitude: beach.longitude)
        )
    }
}
