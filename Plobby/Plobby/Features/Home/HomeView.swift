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
        ScrollView {
            VStack(spacing: 0) {
                header
                recordBanner(height: 240 * scale)
                favoriteBeachSection
                recentRecordSection
                recentRecordRowList
                dailyTipBanner

                // TODO: - 회원/비회원 분기처리
//                switch store.membershipStatus {
//                case .member:
//                    Text("회원 홈화면이지롱")
//
//                case .guest:
//                    Text("비회원 홈화면이지롱")
//                }
            }
        }
        .scrollIndicators(.hidden)
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

// MARK: - 새로 올라온 기록

extension HomeView {

    private var recentRecordSection: some View {
        VStack(spacing: 0) {
            recentRecordHeader
            recentRecordList
        }
        .padding(.top, 40)
    }

    // TODO: coverPhotoKey, profileImageKey로 실제 이미지 불러오기
    /// - 가로 배치 카드
    private func recentRecordCard(_ record: RecordSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            recentRecordCardImage(record)

            recentRecordTitle(record)
                .padding(.top, 8)

            recentRecordMeta(record)
                .padding(.top, 10)

            recentRecordAuthor(record)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // TODO: coverPhotoKey로 실제 이미지 불러오기
    /// - 세로 배치 행
    private func recentRecordRow(_ record: RecordSummary) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                recentRecordTitle(record)

                recentRecordMeta(record)
                    .padding(.top, 10)

                recentRecordAuthor(record)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            recentRecordRowImage(record)
        }
        .padding(.vertical, 13)
    }

    private func recentRecordCardImage(_ record: RecordSummary) -> some View {
        Color.clear
            .aspectRatio(175 / 132, contentMode: .fit)
            .overlay {
                Image(record.recordType.bannerImage)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func recentRecordRowImage(_ record: RecordSummary) -> some View {
        Image(record.recordType.bannerImage)
            .resizable()
            .scaledToFill()
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func recentRecordTitle(_ record: RecordSummary) -> some View {
        Text(record.title)
            .font(.system(size: 17, weight: .semibold))
            .lineLimit(1)
    }

    /// - 몇 시간 전 · 좋아요 수
    private func recentRecordMeta(_ record: RecordSummary) -> some View {
        HStack(spacing: 8) {
            Text(record.createdAt, format: .relative(presentation: .named))

            HStack(spacing: 2) {
                Image(systemName: "heart")
                Text("\(record.likeCount)")
            }
        }
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(.gray)
    }

    private func recentRecordAuthor(_ record: RecordSummary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 16, height: 16)

            Text(record.nickname)
                .font(.system(size: 12, weight: .regular))
                .padding(.leading, 4)
        }
        .foregroundStyle(.gray)
    }
}

extension HomeView {
    
    private var recentRecordHeader: some View {
        HStack {
            Text("새로 올라온 기록")
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            Button("더 보기") {
                store.send(.moreRecentRecordsButtonTapped)
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var recentRecordList: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(store.recentRecordCards) { record in
                recentRecordCard(record)
            }
        }
        .padding(.horizontal, 20)
    }

    private var recentRecordRowList: some View {
        VStack(spacing: 0) {
            ForEach(store.recentRecordRows) { record in
                recentRecordRow(record)

                if record.id != store.recentRecordRows.last?.id {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

// MARK: - 이용 가이드 배너

extension HomeView {

    private var dailyTipBanner: some View {
        Button {
            store.send(.dailyTipBannerTapped)
        } label: {
            Image(.homeDailyTipSeaUrchin)
                .resizable()
                .scaledToFit()
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("하루 상식")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.gray)
                            .padding(.top, 22)
                            .padding(.leading, 20)
                            .padding(.bottom, 8)

                        Text("바다도 사막화가\n된다고?")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 20)
                            .padding(.bottom, 22)
                    }
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 24)
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
