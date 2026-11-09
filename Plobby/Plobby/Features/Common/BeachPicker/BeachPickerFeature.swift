//
//  BeachPickerFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct BeachPickerFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.beaches) var allBeaches
        var selectedRegion: Sea?
        var searchText = ""
        var selectedBeachIDs: [UUID] = []

        var selectedBeaches: [Beach] {
            selectedBeachIDs.compactMap { id in allBeaches.first { $0.id == id } }
        }

        var isSelectionFull: Bool {
            selectedBeachIDs.count >= BeachPickerFeature.maximumCount
        }

        var beaches: [Beach] {
            let beaches = selectedRegion.map { region in
                allBeaches.filter { $0.region == region }
            } ?? allBeaches

            guard !searchText.allSatisfy(\.isWhitespace) else { return beaches }

            return beaches.matching(searchText)
        }
    }

    // MARK: - Action

    enum Action {
        case regionTapped(Sea?)
        case searchTextChanged(String)
        case beachTapped(UUID)
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .regionTapped(region):
                state.selectedRegion = region
                return .none

            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case let .beachTapped(id):
                if let index = state.selectedBeachIDs.firstIndex(of: id) {
                    state.selectedBeachIDs.remove(at: index)
                    return .none
                }

                guard !state.isSelectionFull else {
                    return .none
                }

                state.selectedBeachIDs.append(id)
                return .none
            }
        }
    }
}

// MARK: - Constants

extension BeachPickerFeature {

    nonisolated static let maximumCount = 3
}
