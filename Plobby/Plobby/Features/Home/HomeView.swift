//
//  HomeView.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

import ComposableArchitecture

struct HomeView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<HomeFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                content(scale: DesignScale.fitRatio(for: screenSize(of: proxy)))
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                store.send(.onAppear)
            }
            .onDisappear {
                store.send(.onDisappear)
            }
            .navigationDestination(
                item: $store.scope(state: \.favoriteBeachPicker, action: \.favoriteBeachPicker)
            ) { store in
                FavoriteBeachView(store: store)
            }
        }
    }
}

// MARK: - Subviews

extension HomeView {

    private func content(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            header
            recordBanner(height: 240 * scale)
            favoriteBeachSection

            Spacer()

            switch store.membershipStatus {
            case .member:
                Text("회원 홈화면이지롱")

            case .guest:
                Text("비회원 홈화면이지롱")
            }
        }
    }
}

// MARK: - 헤더

extension HomeView {
    
    private var header: some View {
        HStack {
            Text("홈")
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Button {
                store.send(.notificationButtonTapped)
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.black)
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }
}

// MARK: - 기록하기 배너

extension HomeView {
    
    private func recordBanner(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(HomeFeature.banners, id: \.self) { banner in
                        bannerPage(banner)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: bannerPosition)
            .onBannerDrag(
                started: { store.send(.bannerDragStarted) },
                ended: { store.send(.bannerDragEnded) }
            )

            VStack(spacing: 0) {
                bannerIndicator
                recordButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func screenSize(of proxy: GeometryProxy) -> CGSize {
        CGSize(
            width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing,
            height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
        )
    }

    private var bannerPosition: Binding<RecordType?> {
        Binding(
            get: { store.currentBanner },
            set: { banner in
                guard let banner else { return }
                store.send(.bannerChanged(banner))
            }
        )
    }

    private func bannerPage(_ banner: RecordType) -> some View {
        Image(banner.bannerImage)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(alignment: .topLeading) {
                Text(banner.bannerTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 20)
                    .padding(.leading, 24)
            }
    }

    private var bannerIndicator: some View {
        HStack(spacing: 10) {
            ForEach(HomeFeature.banners, id: \.self) { banner in
                Circle()
                    .fill(banner == store.currentBanner ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.bottom, 14)
    }
    
    // TODO: 디자인 시스템 색상으로 교체
    private var recordButton: some View {
        NormalButton(
            text: store.currentBanner.recordButtonTitle,
            backgroundColor: .green
        ) {
            store.send(.recordButtonTapped)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - 관심 해변

extension HomeView {
    
    private var favoriteBeachSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("관심 해변")
                    .font(.system(size: 20, weight: .semibold))

                Spacer()

                Text("\(store.favoriteBeaches.count)/\(HomeFeature.maximumFavoriteBeachCount)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(store.favoriteBeaches) { beach in
                        favoriteBeachChip(beach)
                    }

                    if store.canAddFavoriteBeach {
                        addFavoriteBeachButton
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 40)
    }

    private func favoriteBeachChip(_ beach: Beach) -> some View {
        BeachChip(title: beach.name, systemImage: "star.fill")
    }

    private var addFavoriteBeachButton: some View {
        Button {
            store.send(.addFavoriteBeachButtonTapped)
        } label: {
            BeachChip(title: "추가", systemImage: "plus", iconColor: .gray, textColor: .gray)
        }
    }
}

// MARK: - View

private extension View {

    @ViewBuilder
    func onBannerDrag(started: @escaping () -> Void, ended: @escaping () -> Void) -> some View {
        if #available(iOS 18.0, *) {
            onScrollPhaseChange { oldPhase, newPhase in
                if newPhase == .interacting {
                    started()
                } else if oldPhase == .interacting {
                    ended()
                }
            }
        } else {
            simultaneousGesture(
                DragGesture()
                    .onChanged { _ in started() }
                    .onEnded { _ in ended() }
            )
        }
    }
}

// MARK: - RecordType

private extension RecordType {

    var bannerImage: ImageResource {
        switch self {
        case .plobbing: .homeBannerPlobbing
        case .plogging: .homeBannerPlogging
        }
    }

    var bannerTitle: String {
        switch self {
        case .plobbing: "다이빙으로,\n바다를 깨끗하게"
        case .plogging: "산책으로,\n해변을 깨끗하게"
        }
    }

    var recordButtonTitle: String {
        switch self {
        case .plobbing: "플로빙 기록하기"
        case .plogging: "플로깅 기록하기"
        }
    }
}
