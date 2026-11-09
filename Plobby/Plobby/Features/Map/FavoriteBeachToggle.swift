//
//  FavoriteBeachToggle.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

import ComposableArchitecture

enum FavoriteBeachToggle {

    enum Outcome: Equatable {
        case toggled(isFavorite: Bool)
        case limitReached
    }

    static func toggle(_ beach: Beach, in favoriteBeaches: Shared<[Beach]>) -> Outcome {
        if favoriteBeaches.wrappedValue.contains(where: { $0.id == beach.id }) {
            favoriteBeaches.withLock { $0.removeAll { $0.id == beach.id } }
            return .toggled(isFavorite: false)
        }

        guard favoriteBeaches.wrappedValue.count < Beach.maximumFavoriteCount else {
            return .limitReached
        }

        favoriteBeaches.withLock { $0.append(beach) }
        return .toggled(isFavorite: true)
    }

    static func revert(_ beach: Beach, isFavorite: Bool, in favoriteBeaches: Shared<[Beach]>) {
        favoriteBeaches.withLock {
            if isFavorite {
                $0.removeAll { $0.id == beach.id }
            } else if !$0.contains(where: { $0.id == beach.id }) {
                $0.append(beach)
            }
        }
    }

    static func request(_ beach: Beach, isFavorite: Bool, beachClient: BeachClient) async throws {
        if isFavorite {
            try await beachClient.submitFavoriteBeach(beach.id)
        } else {
            try await beachClient.removeFavoriteBeach(beach.id)
        }
    }
}
