//
//  HomeFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/1/26.
//

import ComposableArchitecture

@Reducer
struct HomeFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let status: MembershipStatus
    }
    
    // MARK: - Action
    
    enum Action {}
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
