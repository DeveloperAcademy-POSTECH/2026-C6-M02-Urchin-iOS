//
//  OnboardingFeature.swift
//  Plobby
//
//  Created by 더스틴 on 10/27/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct OnboardingFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var currentPage: OnboardingPage = .goal
        var selectedActivity: RecordType = .plogging
        var collectionCard = CollectionCardFeature.State(category: .plastic, collectedCount: 128)
        var signIn = SignInFeature.State()
    }

    // MARK: - Action

    enum Action {
        case activityTabSelected(RecordType)
        case nextButtonTapped
        case pageChanged(OnboardingPage)
        case browseButtonTapped
        case collectionCard(CollectionCardFeature.Action)
        case signIn(SignInFeature.Action)
        case delegate(Delegate)

        enum Delegate {
            case browseWithoutSignUp
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.signIn, action: \.signIn) {
            SignInFeature()
        }
        Scope(state: \.collectionCard, action: \.collectionCard) {
            CollectionCardFeature()
        }

        Reduce { state, action in
            switch action {
            case let .activityTabSelected(activity):
                state.selectedActivity = activity
                return .none

            case .nextButtonTapped:
                guard let next = state.currentPage.next else { return .none }

                state.currentPage = next
                return .none

            case let .pageChanged(page):
                state.currentPage = page
                return .none

            case .browseButtonTapped:
                guard !state.signIn.isSigningIn else { return .none }

                return .send(.delegate(.browseWithoutSignUp))

            case .collectionCard, .signIn, .delegate:
                return .none
            }
        }
    }
}
