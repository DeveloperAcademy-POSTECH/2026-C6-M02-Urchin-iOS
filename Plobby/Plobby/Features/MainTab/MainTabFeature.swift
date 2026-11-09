//
//  MainTabFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

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
        var pendingRecordBeach: Beach?
        var isLoginSheetPresented = false
        var home: HomeFeature.State
        var map = MapFeature.State()
        var collection = CollectionFeature.State()
        var signIn = SignInFeature.State()
    }
    
    // MARK: - Action
    
    enum Action {
        case tabSelected(MainTab)
        case recordMenuDismissed
        case recordTypeSelected(RecordType)
        case loginSheetPresentationChanged(Bool)
        case appleLoginButtonTapped
        case pushTapped(UUID)
        case home(HomeFeature.Action)
        case map(MapFeature.Action)
        case collection(CollectionFeature.Action)
        case recordFlow(PresentationAction<RecordFlowFeature.Action>)
        case signIn(SignInFeature.Action)
        case delegate(Delegate)

        enum Delegate {
            case signedOut
        }
    }

    // MARK: - Dependency

    @Dependency(\.continuousClock) var clock
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Scope(state: \.signIn, action: \.signIn) {
            SignInFeature()
        }
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Scope(state: \.map, action: \.map) {
            MapFeature()
        }
        Scope(state: \.collection, action: \.collection) {
            CollectionFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .recordTypeSelected where state.membershipStatus == .guest:
                state.isRecordMenuPresented = false
                state.pendingRecordBeach = nil
                guard !state.signIn.isSigningIn else { return .none }

                state.isLoginSheetPresented = true
                return .none
                
            case .home(.delegate(.loginRequired)) where !state.signIn.isSigningIn,
                 .collection(.delegate(.loginRequired)) where !state.signIn.isSigningIn,
                 .collection(.my(.presented(.delegate(.loginRequired)))) where !state.signIn.isSigningIn,
                 .map(.delegate(.loginRequired)) where !state.signIn.isSigningIn:
                state.isLoginSheetPresented = true
                return .none
                
            case let .loginSheetPresentationChanged(isPresented):
                state.isLoginSheetPresented = isPresented
                return .none

            case .appleLoginButtonTapped:
                guard !state.signIn.isSigningIn else { return .none }

                state.isLoginSheetPresented = false
                return requestAppleSignInAfterSheetDismissed()

            case let .pushTapped(recordID):
                guard state.recordFlow == nil else { return .none }

                state.isRecordMenuPresented = false
                state.pendingRecordBeach = nil
                state.selectedTab = .home
                state.home.notification = NotificationFeature.State(
                    recordDetail: RecordDetailFeature.State(recordID: recordID)
                )
                return .none

            case let .tabSelected(tab):
                state.selectedTab = tab
                state.isRecordMenuPresented = false
                state.pendingRecordBeach = nil
                return .none
                
            case .recordMenuDismissed:
                state.isRecordMenuPresented = false
                state.pendingRecordBeach = nil
                return .none
                
            case let .recordTypeSelected(recordType):
                state.isRecordMenuPresented = false
                state.recordFlow = RecordFlowFeature.State(recordType: recordType, beach: state.pendingRecordBeach)
                state.pendingRecordBeach = nil
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
            
            case let .map(.delegate(.recordStartRequested(beach))):
                state.isRecordMenuPresented = true
                state.pendingRecordBeach = beach
                return .none
            
            case .map:
                return .none
            
            case .collection(.my(.presented(.delegate(.signInRequested)))):
                return .send(.signIn(.appleSignInRequested))

            case .collection(.my(.presented(.delegate(.signedOut)))):
                return .send(.delegate(.signedOut))

            case .collection, .recordFlow, .signIn, .delegate:
                return .none
            }
        }
        .ifLet(\.$recordFlow, action: \.recordFlow) {
            RecordFlowFeature()
        }
    }
}

// MARK: - Functions

private extension MainTabFeature {

    static let sheetDismissDelay: Duration = .milliseconds(350)

    func requestAppleSignInAfterSheetDismissed() -> Effect<Action> {
        .run { send in
            try await clock.sleep(for: Self.sheetDismissDelay)
            await send(.signIn(.appleSignInRequested))
        }
    }
}
