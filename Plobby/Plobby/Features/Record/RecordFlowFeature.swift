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
        let beach: Beach?
        var step: Step.State
        var prefetchedGoal: Goal?
        
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
        case collecting(RecordCollectingFeature)
        case reward(RecordRewardFeature)
        case detail(RecordDetailFeature)
    }
    
    // MARK: - Action
    
    enum Action {
        case step(Step.Action)
        case profilePrefetched(Result<Profile?, any Error>)
        case goalPrefetched(Result<Goal?, any Error>)
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
    @Dependency(\.userClient) var userClient
    @Dependency(\.goalClient) var goalClient
    
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
                state.step = .collecting(.init(recordID: recordID, beachName: beachName, trash: trash, weightKg: weightKg))

                let now = now
                return .run { send in
                    async let profile = Result { try await userClient.fetchMyProfile() }
                    async let goal = Result { try await goalClient.fetchCurrentGoal(now) }
                    await send(.profilePrefetched(profile))
                    await send(.goalPrefetched(goal))
                }

            case let .profilePrefetched(.success(profile)):
                @Shared(.myProfile) var myProfile
                $myProfile.withLock { $0 = profile }
                return .none

            case let .profilePrefetched(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case let .goalPrefetched(.success(goal)):
                state.prefetchedGoal = goal
                return .none

            case let .goalPrefetched(.failure(error)):
                PlobbyLogger.error(error)
                return .none

            case .step(.collecting(.delegate(.finished))):
                guard case let .collecting(collecting) = state.step else { return .none }
                state.step = .reward(.init(
                    recordID: collecting.recordID,
                    beachName: collecting.beachName,
                    trash: collecting.trash,
                    weightKg: collecting.weightKg,
                    goal: state.prefetchedGoal
                ))
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
