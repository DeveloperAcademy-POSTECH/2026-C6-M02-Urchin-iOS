//
//  RegionFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import ComposableArchitecture

@Reducer
struct RegionFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var selectedSea: Sea = .all
        var searchText = ""
        
        var regions: [String] {
            guard !searchText.isEmpty else { return selectedSea.regions }

            return selectedSea.regions.filter { $0.contains(searchText) }
        }
    }

    // MARK: - Action
    
    enum Action {
        case seaTapped(Sea)
        case searchTextChanged(String)
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
                
            case .nextButtonTapped:
                return .none
            }
        }
    }
}
