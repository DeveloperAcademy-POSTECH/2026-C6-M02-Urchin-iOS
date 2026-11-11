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
    @State private var dragOffset: CGFloat = 0

    private static let pageAnimation: Animation = .easeInOut(duration: 0.3)
    private static let backSwipeEdgeWidth: CGFloat = 32
    private static let backSwipeThreshold: CGFloat = 100

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(stackedPages, id: \.self) { page in
                card(page)
            }
        }
        .animation(Self.pageAnimation, value: store.currentPage)
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
    }
}

// MARK: - 카드 전환

private extension OnboardingView {

    var stackedPages: [OnboardingPage] {
        OnboardingPage.allCases.filter { $0.rawValue <= store.currentPage.rawValue }
    }

    func card(_ page: OnboardingPage) -> some View {
        let isTop = page == store.currentPage

        return pageView(page)
            .shadow(color: Color(.neutralBlack).opacity(isTop ? 0.12 : 0), radius: 16)
            .offset(x: isTop ? dragOffset : 0)
            .zIndex(Double(page.rawValue))
            .transition(.blurFade)
            .gesture(backSwipe(from: page), isEnabled: isTop)
    }

    func backSwipe(from page: OnboardingPage) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard page.previous != nil, value.startLocation.x < Self.backSwipeEdgeWidth else { return }
                dragOffset = max(0, value.translation.width)
            }
            .onEnded { value in
                guard let previous = page.previous, dragOffset > 0 else { return }

                withAnimation(Self.pageAnimation) {
                    if value.predictedEndTranslation.width > Self.backSwipeThreshold {
                        store.send(.pageChanged(previous))
                    }
                    dragOffset = 0
                }
            }
    }

    func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            header(page)
            titleSection(page)

            if page.showsActivityTabs {
                activityTabs(page)
                    .animation(.easeInOut(duration: 0.2), value: selectedActivity(on: page))
            }

            if page == .collection {
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
    }
}

// MARK: - 상단 (헤더, 제목)

private extension OnboardingView {

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

    func selectedActivity(on page: OnboardingPage) -> RecordType {
        store.selectedActivities[page] ?? .plogging
    }

    func activityTabs(_ page: OnboardingPage) -> some View {
        HStack(spacing: 0) {
            activityTab(.plogging, title: "플로깅", page: page)
            activityTab(.plobbing, title: "플로빙", page: page)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.borderDefault))
                .frame(height: 1)
        }
        .padding(.top, 16.scaled)
        .padding(.horizontal, 20.scaled)
    }

    func activityTab(_ activity: RecordType, title: String, page: OnboardingPage) -> some View {
        let isSelected = selectedActivity(on: page) == activity

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
            Image(page.illustration(for: selectedActivity(on: page)))
                .resizable()
                .scaledToFit()
                .frame(width: page.illustrationWidth.scaled)
                .accessibilityLabel(page.illustrationLabel)
            
        case .collection:
            CollectionCardView(store: store.scope(state: \.collectionCard, action: \.collectionCard), style: .onboarding)
                .frame(width: 280.scaled, height: 428.scaled)
        }
    }
}

// MARK: - 하단 버튼

private extension OnboardingView {

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

// MARK: - OnboardingPage

private extension OnboardingPage {

    var illustrationTopPadding: CGFloat {
        switch self {
        case .goal, .record, .collection: 16
        case .map: 8
        }
    }

    var illustrationWidth: CGFloat {
        self == .map ? 344 : 360
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
        case .goal: "공통 목표 예시 화면"
        case .record: "기록 상세 예시 화면"
        case .map: "지도 예시 화면"
        case .collection: "컬렉션 카드 예시"
        }
    }
}

// MARK: - Transition

private struct BlurModifier: ViewModifier {

    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

private extension AnyTransition {

    static var blurFade: AnyTransition {
        .modifier(active: BlurModifier(radius: 8), identity: BlurModifier(radius: 0))
            .combined(with: .opacity)
    }
}
