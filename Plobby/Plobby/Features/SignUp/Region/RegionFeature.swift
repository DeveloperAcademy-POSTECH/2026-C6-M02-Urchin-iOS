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
        var selectedSea: Sea = .all
        var searchText = ""
        var selectedBeachIDs: Set<UUID> = []
        
        var beaches: [Beach] {
            let beaches = selectedSea == .all
                ? Beach.all
                : Beach.all.filter { $0.region == selectedSea.title }
            
            guard !searchText.isEmpty else { return beaches }
            
            return beaches.filter { $0.name.contains(searchText) }
        }
    }

    // MARK: - Action
    
    enum Action {
        case seaTapped(Sea)
        case searchTextChanged(String)
        case beachTapped(UUID)
        case nextButtonTapped
    }

    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .seaTapped(sea):
                state.selectedSea = sea
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
