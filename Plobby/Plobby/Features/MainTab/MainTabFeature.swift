//
//  MainTabFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import ComposableArchitecture

@Reducer
struct MainTabFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
        @Presents var recordFlow: RecordFlowFeature.State?

        var selectedTab: MainTab = .home
        var isRecordMenuPresented = false
        var isLoginSheetPresented = false
        var home: HomeFeature.State
        var map = MapFeature.State()
        var my = MyFeature.State()
    }
    
    // MARK: - Action
    
    enum Action {
        case tabSelected(MainTab)
        case recordMenuDismissed
        case recordTypeSelected(RecordType)
        case loginSheetPresentationChanged(Bool)
        case home(HomeFeature.Action)
        case map(MapFeature.Action)
        case my(MyFeature.Action)
        case recordFlow(PresentationAction<RecordFlowFeature.Action>)
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapFeature()
        }
        Scope(state: \.my, action: \.my) {
            MyFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .recordTypeSelected where state.isGuest:
                state.isRecordMenuPresented = false
                state.isLoginSheetPresented = true
                return .none
                
            case .home(.delegate(.loginRequired)):
                state.isLoginSheetPresented = true
                return .none
                
            case let .loginSheetPresentationChanged(isPresented):
                state.isLoginSheetPresented = isPresented
                return .none
                
            case .tabSelected(.record):
                state.isRecordMenuPresented.toggle()
                return .none
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                state.isRecordMenuPresented = false
                return .none
                
            case .recordMenuDismissed:
                state.isRecordMenuPresented = false
                return .none
                
            case let .recordTypeSelected(recordType):
                state.isRecordMenuPresented = false
                state.recordFlow = RecordFlowFeature.State(recordType: recordType)
                return .none
                
            case .recordFlow(.presented(.delegate(.closed))):
                state.recordFlow = nil
                return .none
                
            case .recordFlow(.presented(.delegate(.recordDeleted))):
                state.recordFlow = nil
                state.selectedTab = .home
                return .none
                
            case let .home(.delegate(.recordStarted(recordType))):
                return .send(.recordTypeSelected(recordType))
            
            case .home:
                return .none
            
            case .map:
                return .none
            
            case .my:
                return .none
            
            case .recordFlow:
                return .none
            }
        }
        .ifLet(\.$recordFlow, action: \.recordFlow) {
            RecordFlowFeature()
        }
    }
}

// MARK: - State

private extension MainTabFeature.State {

    var isGuest: Bool {
        if case .guest = membershipStatus { true } else { false }
    }
}
