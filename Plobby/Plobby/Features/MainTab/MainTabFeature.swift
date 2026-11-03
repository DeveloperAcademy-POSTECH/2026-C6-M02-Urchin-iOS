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
        var selectedTab: MainTab = .home
        var isRecordSheetPresented = false
        var home: HomeFeature.State
        var map = MapFeature.State()
        var my = MyFeature.State()
        @Presents var record: RecordFeature.State?
    }
    
    // MARK: - Action
    
    enum Action {
        case tabSelected(MainTab)
        case recordSheetPresentedChanged(Bool)
        case home(HomeFeature.Action)
        case map(MapFeature.Action)
        case my(MyFeature.Action)
        case record(PresentationAction<RecordFeature.Action>)
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
            case .tabSelected(.record):
                state.isRecordSheetPresented = true
                return .none
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
            case let .recordSheetPresentedChanged(isPresented):
                state.isRecordSheetPresented = isPresented
                return .none
            case .home:
                return .none
            case .map:
                return .none
            case .my:
                return .none
            case .record:
                return .none
            }
        }
        .ifLet(\.$record, action: \.record) {
            RecordFeature()
        }
    }
}
