//
//  SignUpFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import ComposableArchitecture

@Reducer
struct SignUpFeature {
    
    // MARK: - Path
    
    @Reducer(state: .equatable)
    enum Path {
        case region(RegionFeature)
        case complete(CompleteFeature)
    }

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let user: AuthUser
        var fullName: String?
        var path = StackState<Path.State>()
    }

    // MARK: - Action
    
    enum Action {
        case nextButtonTapped
        case path(StackActionOf<Path>)
    }
    
    // MARK: - Dependency
    
    @Dependency(\.authClient) var authClient

    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextButtonTapped:
                state.path.append(.region(RegionFeature.State()))
                return .none

            case .path(.element(id: _, action: .region(.nextButtonTapped))):
                state.path.append(.complete(CompleteFeature.State()))
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
