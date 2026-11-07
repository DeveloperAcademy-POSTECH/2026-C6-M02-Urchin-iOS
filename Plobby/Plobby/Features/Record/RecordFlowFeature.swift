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
        /// 지도에서 해변을 골라 시작하면 기록 작성 화면에 미리 채워요
        let beach: Beach?
        var step: Step.State
        
        init(recordType: RecordType, beach: Beach? = nil, step: Step.State? = nil) {
            self.recordType = recordType
            self.beach = beach
            self.step = step ?? .photoPicker(PhotosPickerFeature.State(recordType: recordType))
        }
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
            case recordDeleted
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.step, action: \.step) {
            Step.body
        }
        
        Reduce { state, action in
            switch action {
            case let .step(.photoPicker(.delegate(.finished(photos)))):
                state.step = .form(.init(
                    recordType: state.recordType,
                    photos: IdentifiedArray(uniqueElements: photos.map(RecordPhoto.local)),
                    beach: state.beach,
                    period: .defaultPeriod(endingAt: now, calendar: calendar)
                ))
                return .none
                
            case let .step(.form(.delegate(.recordCreated(recordID, beachName, trash, weightKg)))):
                state.step = .reward(.init(recordID: recordID, beachName: beachName, trash: trash, weightKg: weightKg))
                return .none
                
            case let .step(.reward(.delegate(.finished(recordID)))):
                state.step = .detail(.init(recordID: recordID))
                return .none
                
            case .step(.photoPicker(.delegate(.cancelled))),
                    .step(.form(.delegate(.closed))),
                    .step(.reward(.delegate(.closed))),
                    .step(.detail(.delegate(.closed))):
                return .send(.delegate(.closed))
                
            case .step(.detail(.delegate(.deleted))):
                return .send(.delegate(.recordDeleted))
                
            case .step, .delegate:
                return .none
            }
        }
    }
}

extension RecordFlowFeature.Step.State: Equatable {}
