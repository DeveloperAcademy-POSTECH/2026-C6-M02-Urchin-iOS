//
//  RegionFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RegionFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        @Shared(.beaches) var allBeaches
        var selectedRegion: BeachRegion?
        var searchText = ""
        var selectedBeachIDs: Set<UUID> = []
        
        var beaches: [Beach] {
            let beaches = selectedRegion.map { region in
                allBeaches.filter { $0.region == region.displayName }
            } ?? allBeaches
            
            guard !searchText.isEmpty else { return beaches }
            
            return beaches.filter { $0.name.contains(searchText) }
        }
    }

    // MARK: - Action
    
    enum Action {
        case regionTapped(BeachRegion?)
        case searchTextChanged(String)
        case beachTapped(UUID)
        case nextButtonTapped
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
                if state.selectedBeachIDs.remove(id) != nil {
                    return .none
                }
                
                guard state.selectedBeachIDs.count < RegionFeature.maximumBeachCount else {
                    return .none
                }
                
                state.selectedBeachIDs.insert(id)
                return .none
                
            case .nextButtonTapped:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension RegionFeature {

    private static let maximumBeachCount = 3
}
