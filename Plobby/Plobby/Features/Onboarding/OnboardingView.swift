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
        // 1단계가 시작 화면이고, 2~4단계는 push돼요
        NavigationStack(path: path) {
            pageView(.goal)
                .navigationDestination(for: OnboardingPage.self) { page in
                    // push된 화면도 탭 선택·카드 뒤집기 같은 스토어 변화를 바로 반영하도록 자기 body에서 그려요
                    ObservingView { pageView(page) }
                }
        }
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
    }
}

// MARK: - 내비게이션

private extension OnboardingView {

    /// 지금 단계까지 쌓인 화면들 (시작 화면인 1단계 제외)
    var path: Binding<[OnboardingPage]> {
        Binding(
            get: { OnboardingPage.allCases.filter { $0 != .goal && $0.rawValue <= store.currentPage.rawValue } },
            set: { store.send(.pageChanged($0.last ?? .goal)) }
        )
    }

    func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            header(page)
            titleSection(page)

            if page.showsActivityTabs {
                activityTabs
                    // push된 화면에서는 send(animation:)의 트랜잭션이 전달되지 않아, 뷰에서 직접 애니메이션을 걸어 모든 단계를 같게 맞춰요
                    .animation(.easeInOut(duration: 0.2), value: store.selectedActivity)
            }

            if page == .collection {
                // 컬렉션 카드(280x428, 시안 기준 좌우 60)는 하단 버튼 위 40에 놓여요
                Spacer(minLength: 0)

                illustration(page)
                    .padding(.bottom, 40.scaled)
            } else {
                illustration(page)
                    .padding(.top, page.illustrationTopPadding.scaled)

                Spacer(minLength: 0)
            }

            bottomButtons(page)
        }
        .background(Color(.backgroundDefault))
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - 상단 (헤더, 제목)

private extension OnboardingView {

    /// 공통 네비게이션 바(높이 56). 첫 단계는 뒤로가기 없이 높이만 차지해요
    @ViewBuilder
    func header(_ page: OnboardingPage) -> some View {
        if let previous = page.previous {
            PlobbyNavigationBar {
                store.send(.pageChanged(previous))
            }
        } else {
            Color.clear
                .frame(height: 56.scaled)
        }
    }

    func titleSection(_ page: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            HStack(alignment: .top, spacing: 16.scaled) {
                Text(page.title)
                    .plobbyFont(.metric)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)

                pageNumber(page)
                    .padding(.top, 4.scaled)
            }

            Text(page.description)
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8.scaled)
        .padding(.bottom, 12.scaled)
        .padding(.horizontal, 20.scaled)
    }

    func pageNumber(_ page: OnboardingPage) -> some View {
        Text("\(Text("\(page.number)").foregroundStyle(Color(.textBrand))) / \(OnboardingPage.allCases.count)")
            .plobbyFont(.labelSelected)
            .foregroundStyle(Color(.textSecondary))
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
        .padding(.top, 16.scaled)
        .padding(.horizontal, 20.scaled)
    }

    func activityTab(_ activity: RecordType, title: String) -> some View {
        let isSelected = store.selectedActivity == activity

        return Button {
            store.send(.activityTabSelected(activity))
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
    func illustration(_ page: OnboardingPage) -> some View {
        switch page {
        case .goal, .record, .map:
            // 예시 화면은 그림자 여백까지 포함한 이미지예요
            Image(page.illustration(for: store.selectedActivity))
                .resizable()
                .scaledToFit()
                .frame(width: page.illustrationWidth.scaled)
                // 플로깅/플로빙 이미지 높이가 달라도(기록 396 / 424) 같은 영역을 차지해 탭을 바꿔도 화면이 흔들리지 않아요
                .frame(height: page.illustrationHeight.scaled, alignment: .top)
                .accessibilityLabel(page.illustrationLabel)
        case .collection:
            CollectionCardView(store: store.scope(state: \.collectionCard, action: \.collectionCard), style: .onboarding)
                .frame(width: 280.scaled, height: 428.scaled)
        }
    }
}

// MARK: - 하단 버튼

private extension OnboardingView {

    /// 다음 버튼과 Apple 로그인 버튼은 같은 자리에 와요. 둘러보기는 Apple 로그인 바로 아래에 붙어요
    func bottomButtons(_ page: OnboardingPage) -> some View {
        Group {
            if page.isLast {
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
        // 시안 하단 여백 68에서 홈 인디케이터 영역(34)을 뺀 값
        .padding(.bottom, 34.scaled)
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

    var browseButton: some View {
        Button {
            store.send(.browseButtonTapped)
        } label: {
            Text("회원가입 없이 둘러보기")
                .plobbyFont(.helper)
                .foregroundStyle(Color(.gray700))
                .frame(maxWidth: .infinity)
                .frame(height: 48.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ObservingView

/// 내비게이션 destination 안의 내용이 스토어 변화를 놓치지 않도록, 내용을 자기 body에서 다시 그려요
private struct ObservingView<Content: View>: View {

    let content: () -> Content

    var body: some View {
        content()
    }
}

// MARK: - OnboardingPage

private extension OnboardingPage {

    /// 예시 화면 위 여백. 시안 간격(탭 아래 24, 제목 영역 아래 16)에서 이미지에 포함된 그림자 여백(8)을 뺐어요
    var illustrationTopPadding: CGFloat {
        switch self {
        case .goal, .record: 16
        case .map: 8
        case .collection: 16
        }
    }

    /// 이미지 폭. 카드(320)에 좌우 그림자 여백이 더해져 있어요
    var illustrationWidth: CGFloat {
        self == .map ? 344 : 360
    }

    /// 이미지 영역 높이. 플로깅/플로빙 중 더 큰 이미지 기준이에요
    var illustrationHeight: CGFloat {
        self == .map ? 456 : 424
    }

    func illustration(for activity: RecordType) -> ImageResource {
        switch (self, activity) {
        case (.goal, .plogging): .onboardingGoalPlogging
        case (.goal, .plobbing): .onboardingGoalPlobbing
        case (.record, .plogging): .onboardingRecordPlogging
        case (.record, .plobbing): .onboardingRecordPlobbing
        default: .onboardingMap
        }
    }

    var illustrationLabel: String {
        switch self {
        case .goal: "공동 목표 예시 화면"
        case .record: "기록 상세 예시 화면"
        case .map: "지도 예시 화면"
        case .collection: "컬렉션 카드 예시"
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
