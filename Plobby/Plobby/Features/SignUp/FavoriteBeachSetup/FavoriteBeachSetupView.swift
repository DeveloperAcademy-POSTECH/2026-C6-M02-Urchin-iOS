//
//  FavoriteBeachSetupView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct FavoriteBeachSetupView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<FavoriteBeachSetupFeature>
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                PlobbyNavigationBar(title: "회원가입") {
                    store.send(.backButtonTapped)
                }

                progressBar
                titleSection
                beachPicker
                bottomSection
            }
        }
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden, for: .navigationBar)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
    }
}

// MARK: - Keyboard

private extension FavoriteBeachSetupView {

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Subviews

private extension FavoriteBeachSetupView {
    
    var progressBar: some View {
        SignUpProgressBar(currentStep: 2, totalSteps: 2)
            .padding(.top, 23.scaled)
            .padding(.bottom, 31.scaled)
            .padding(.horizontal, 20.scaled)
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("관심 해변을 골라 주세요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("최대 3개까지 고르고, 마이페이지에서 바꿀 수 있어요")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20.scaled)
    }
    
    var beachPicker: some View {
        BeachPickerView(store: store.scope(state: \.picker, action: \.picker), regionSectionHeight: nil)
            .padding(.top, 24.scaled)
            .padding(.bottom, 16.scaled)
            .padding(.horizontal, 20.scaled)
    }
}

// MARK: - 하단 (고른 해변, 가입하기)

private extension FavoriteBeachSetupView {

    var bottomSection: some View {
        BeachPickerBottomBar(
            store: store.scope(state: \.picker, action: \.picker),
            emptyMessage: "해변을 선택하면 가입할 수 있어요",
            buttonTitle: "가입하기",
            isButtonDisabled: store.picker.selectedBeachIDs.isEmpty
        ) {
            store.send(.signUpButtonTapped)
        }
    }
}
