//
//  MyFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct MyFeature {

    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
    }

    enum Action {

    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            }
        }
    }
}
