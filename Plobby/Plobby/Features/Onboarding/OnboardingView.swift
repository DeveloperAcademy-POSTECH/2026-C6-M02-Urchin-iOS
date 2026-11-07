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
        VStack(alignment: .center, spacing: 0) {
            pageContent
            appleLoginButton
            browseButton
        }
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Subviews

extension OnboardingView {
    
    private var pageContent: some View {
        VStack(alignment: .center, spacing: 0) {
            indicator

            pageImage

            pageDescription
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.screenTapped)
        }
    }
    
    private var indicator: some View {
        OnboardingPageIndicator(
            currentIndex: store.currentPageIndex,
            pageCount: OnboardingPage.allCases.count
        )
        .padding(.top, 20.scaled)
        .padding(.horizontal, 65.scaled)
    }
    
    private var pageImage: some View {
        Image(store.currentPage.image)
            .resizable()
            .scaledToFit()
            .scaleEffect(store.currentPage.imageScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20.scaled)
            .padding(.vertical, 24.scaled)
            .animation(.easeInOut(duration: 0.3), value: store.currentPage)
    }

    private var pageDescription: some View {
        VStack(alignment: .center, spacing: 12.scaled) {
            Text(store.currentPage.title)
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: store.currentPage.titleSize.scaled))
            
            Text(store.currentPage.description)
                .font(.custom(PretendardWeight.regular.rawValue, fixedSize: store.currentPage.descriptionSize.scaled))
        }
        .foregroundStyle(Color(.neutralBlack))
        .multilineTextAlignment(.center)
        .animation(.easeInOut(duration: 0.3), value: store.currentPage)
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 77.scaled)
    }
    
    private var appleLoginButton: some View {
        Button {
            store.send(.signIn(.appleSignInRequested))
        } label: {
            AppleLoginLabel()
        }
        .disabled(store.signIn.isSigningIn)
        .padding(.horizontal, CGFloat(38.5).scaled)
        .padding(.bottom, 17.scaled)
    }
    
    // TODO: 컬러셋 확정 후 교체 (#555D6D)
    private static let browseTextColor = Color(red: 0x55 / 255, green: 0x5D / 255, blue: 0x6D / 255)

    private var browseButton: some View {
        Button {
            store.send(.browseButtonTapped)
        } label: {
            Text("회원가입 없이 둘러보기")
                .font(.custom(PretendardWeight.regular.rawValue, fixedSize: 14.scaled))
                .foregroundStyle(Self.browseTextColor)
        }
        .padding(.bottom, 17.scaled)
    }
}

// MARK: - OnboardingPage

private extension OnboardingPage {

    var titleSize: CGFloat {
        self == .trashAmount ? 36 : 28
    }

    var descriptionSize: CGFloat {
        self == .trashAmount ? 17 : 16
    }

    var imageScale: CGFloat {
        switch self {
        case .trashAmount, .together: 0.6
        case .record, .photo: 1
        }
    }
}
