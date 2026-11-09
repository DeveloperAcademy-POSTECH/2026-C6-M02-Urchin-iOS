//
//  OnboardingView.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

import ComposableArchitecture

struct OnboardingView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<OnboardingFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            pageNumber
            titleSection

            if store.currentPage.showsActivityTabs {
                activityTabs
            }

            illustration
                .padding(.top, store.currentPage.illustrationTopPadding.scaled)

            Spacer(minLength: 0)

            bottomButtons
        }
        .background(Color(.backgroundDefault))
        .animation(.easeInOut(duration: 0.25), value: store.currentPage)
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
    }
}

// MARK: - 상단 (단계 번호, 제목)

private extension OnboardingView {

    var pageNumber: some View {
        Text("\(Text("\(store.currentPage.number)").foregroundStyle(Color(.textBrand))) / \(OnboardingPage.allCases.count)")
            .plobbyFont(.labelSelected)
            .foregroundStyle(Color(.textSecondary))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 4.scaled)
            .padding(.horizontal, 20.scaled)
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text(store.currentPage.title)
                .plobbyFont(.headingLarge)
                .foregroundStyle(Color(.textPrimary))

            Text(store.currentPage.description)
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8.scaled)
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - 플로깅/플로빙 탭

private extension OnboardingView {

    var activityTabs: some View {
        HStack(spacing: 0) {
            activityTab(.plogging, title: "플로깅")
            activityTab(.plobbing, title: "플로빙")
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.borderDefault))
                .frame(height: 1)
        }
        .padding(.top, 32.scaled)
        .padding(.horizontal, 20.scaled)
    }

    func activityTab(_ activity: RecordType, title: String) -> some View {
        let isSelected = store.selectedActivity == activity

        return Button {
            store.send(.activityTabSelected(activity), animation: .easeInOut(duration: 0.2))
        } label: {
            Text(title)
                .plobbyFont(isSelected ? .actionLabel : .body)
                .foregroundStyle(isSelected ? Color(.textPrimary) : Color(.textSecondary))
                .frame(maxWidth: .infinity)
                .frame(height: 52.scaled)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Color(.brandPrimary))
                            .frame(height: 4.scaled)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 예시 화면

private extension OnboardingView {

    @ViewBuilder
    var illustration: some View {
        switch store.currentPage {
        case .record:
            OnboardingRecordMock(activity: store.selectedActivity)
        case .goal:
            OnboardingGoalMock(activity: store.selectedActivity)
        case .map:
            OnboardingMapMock()
        case .collection:
            CollectionCardView(store: store.scope(state: \.collectionCard, action: \.collectionCard))
                .frame(width: 280.scaled, height: 428.scaled)
        }
    }
}

// MARK: - 하단 버튼

private extension OnboardingView {

    /// 다음 버튼과 Apple 로그인 버튼은 같은 자리에 와요. 둘러보기는 Apple 로그인 바로 아래에 붙어요
    var bottomButtons: some View {
        Group {
            if store.currentPage.isLast {
                appleLoginButton
                    .overlay(alignment: .bottom) {
                        browseButton
                            .offset(y: 48.scaled)
                    }
            } else {
                PlobbyButton(text: "다음") {
                    store.send(.nextButtonTapped)
                }
            }
        }
        .padding(.horizontal, 20.scaled)
        // 시안 하단 여백 56에서 홈 인디케이터 영역(34)을 뺀 값
        .padding(.bottom, 22.scaled)
    }

    var appleLoginButton: some View {
        Button {
            store.send(.signIn(.appleSignInRequested))
        } label: {
            AppleLoginLabel()
        }
        .buttonStyle(.plain)
        .disabled(store.signIn.isSigningIn)
    }

    // TODO: 컬러셋 확정 후 교체 (#555D6D)
    static let browseTextColor = Color(red: 0x55 / 255, green: 0x5D / 255, blue: 0x6D / 255)

    var browseButton: some View {
        Button {
            store.send(.browseButtonTapped)
        } label: {
            Text("회원가입 없이 둘러보기")
                .plobbyFont(.helper)
                .foregroundStyle(Self.browseTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 48.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - OnboardingPage

private extension OnboardingPage {

    /// 예시 화면 위 여백. 탭이 있는 단계는 탭 아래 36, 없는 단계는 설명 아래 간격이에요
    var illustrationTopPadding: CGFloat {
        switch self {
        case .record, .goal: 36
        case .map: 40
        case .collection: 48
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
