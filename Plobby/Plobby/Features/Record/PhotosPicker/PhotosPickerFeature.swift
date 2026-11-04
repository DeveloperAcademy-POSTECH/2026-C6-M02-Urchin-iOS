//
//  PhotosPickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct PhotosPickerFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        var maxSelectionCount: Int = 5
        var selectedPhotos: IdentifiedArrayOf<PhotoAsset> = []
    }
    
    // MARK: - Action
    
    enum Action {
        case nextButtonTapped
        case closeButtonTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case finished([PhotoAsset])
            case cancelled
        }
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextButtonTapped:
                return .send(.delegate(.finished(Array(state.selectedPhotos))))
            case .closeButtonTapped:
                return .send(.delegate(.cancelled))
            case .delegate:
                return .none
            }
        }
    }
}
