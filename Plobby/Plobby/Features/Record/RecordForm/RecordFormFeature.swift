//
//  RecordFormFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RecordFormFeature {

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let recordType: RecordType
    }
    
    // MARK: - Action
    
    enum Action {
        case saveButtonTapped
        case closeButtonTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case recordCreated(UUID)
            case closed
        }
    }
    
    // TODO: - 기록 저장 구현 시 recordClient.submitRecord 결과의 ID로 교체
    @Dependency(\.uuid) var uuid
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                return .send(.delegate(.recordCreated(uuid())))
            case .closeButtonTapped:
                return .send(.delegate(.closed))
            case .delegate:
                return .none
            }
        }
    }
}
