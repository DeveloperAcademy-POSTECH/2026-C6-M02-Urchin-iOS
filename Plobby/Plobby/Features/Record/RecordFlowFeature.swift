//
//  RecordFlowFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct RecordFlowFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let recordType: RecordType
        var step: Step.State = .photoPicker(PhotosPickerFeature.State())
    }
    
    // MARK: - Step
    
    @Reducer
    enum Step {
        case photoPicker(PhotosPickerFeature)
        case form(RecordFormFeature)
        case reward(RecordRewardFeature)
        case detail(RecordDetailFeature)
    }
    
    // MARK: - Action
    
    enum Action {
        case step(Step.Action)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case closed
        }
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.step, action: \.step) {
            Step.body
        }
        
        Reduce { state, action in
            switch action {
            case .step(.photoPicker(.delegate(.finished))):
                state.step = .form(.init(recordType: state.recordType))
                return .none
                
            case let .step(.form(.delegate(.recordCreated(recordID)))):
                state.step = .reward(.init(recordID: recordID))
                return .none
                
            case let .step(.reward(.delegate(.finished(recordID)))):
                state.step = .detail(.init(recordID: recordID))
                return .none
                
            case .step(.photoPicker(.delegate(.cancelled))),
                    .step(.form(.delegate(.closed))),
                    .step(.reward(.delegate(.closed))),
                    .step(.detail(.delegate(.closed))):
                return .send(.delegate(.closed))
                
            case .step, .delegate:
                return .none
            }
        }
    }
}

extension RecordFlowFeature.Step.State: Equatable {}
