//
//  TermsAgreementFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import ComposableArchitecture

@Reducer
struct TermsAgreementFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var isAgeConfirmed = false
        var isTermsAgreed = false
        var isPrivacyAgreed = false

        var isAllAgreed: Bool {
            isAgeConfirmed && isTermsAgreed && isPrivacyAgreed
        }
    }

    // MARK: - Action

    enum Action {
        case allAgreementTapped
        case ageConfirmationTapped
        case termsAgreementTapped
        case privacyAgreementTapped
        case nextButtonTapped
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .allAgreementTapped:
                let isAgreed = !state.isAllAgreed
                state.isAgeConfirmed = isAgreed
                state.isTermsAgreed = isAgreed
                state.isPrivacyAgreed = isAgreed
                return .none

            case .ageConfirmationTapped:
                state.isAgeConfirmed.toggle()
                return .none

            case .termsAgreementTapped:
                state.isTermsAgreed.toggle()
                return .none

            case .privacyAgreementTapped:
                state.isPrivacyAgreed.toggle()
                return .none

            case .nextButtonTapped:
                return .none
            }
        }
    }
}
