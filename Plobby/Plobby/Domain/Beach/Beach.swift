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

nonisolated extension Beach {

    static let maximumFavoriteCount = 3
    
    var coordinate: Coordinate {
        .init(latitude: latitude, longitude: longitude)
    }

    func matches(_ query: String) -> Bool {
        let keyword = query.searchKeyword
        guard !keyword.isEmpty else { return false }

        return name.searchKeyword.contains(keyword) || address.searchKeyword.contains(keyword)
    }
}

nonisolated extension [Beach] {

    func matching(_ query: String) -> [Beach] {
        let keyword = query.searchKeyword
        guard !keyword.isEmpty else { return [] }

        let matched = filter { $0.matches(keyword) }
        let nameMatched = matched.filter { $0.name.searchKeyword.contains(keyword) }
        let addressOnlyMatched = matched.filter { !$0.name.searchKeyword.contains(keyword) }

        return nameMatched + addressOnlyMatched
    }
}

private nonisolated extension String {

    var searchKeyword: String {
        filter { !$0.isWhitespace }.lowercased()
    }
}
