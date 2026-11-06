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
        content
            .onAppear {
                store.send(.onAppear)
            }
            .onDisappear {
                store.send(.onDisappear)
            }
    }
}

// MARK: - Subviews

extension HomeView {

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                recordBanner
                recentRecordSection
                recentRecordRowList
                // TODO: 이용 가이드 콘텐츠가 준비되면 dailyTipBanner 다시 표시
            }
            .padding(.bottom, 36.scaled)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await store.send(.refreshPulled).finish()
        }
    }
}

// MARK: - 헤더

extension HomeView {
    
    private var header: some View {
        HStack {
            Text("홈")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Spacer()

            Button {
                store.send(.notificationButtonTapped)
            } label: {
                Image(.bell)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24.scaled, height: 24.scaled)
            }
        }
        .frame(height: 56.scaled)
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - 기록하기 배너

extension HomeView {
    
    private var recordBanner: some View {
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

            recordButton
                .padding(.horizontal, 20.scaled)
                .padding(.bottom, 16.scaled)
        }
        .overlay(alignment: .topTrailing) {
            bannerIndicator
                .padding(.top, 18.scaled)
                .padding(.trailing, 10.scaled)
        }
        .aspectRatio(362 / 180, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16.scaled))
        .padding(.horizontal, 20.scaled)
        .padding(.top, 16.scaled)
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
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 18.scaled))
                    .foregroundStyle(Color(.textPrimary))
                    .padding(.top, 20.scaled)
                    .padding(.leading, 24.scaled)
            }
    }

    // TODO: 컬러셋 확정 후 교체 (#ACC9BE)
    private static let inactiveIndicatorColor = Color(red: 0xAC / 255, green: 0xC9 / 255, blue: 0xBE / 255)

    private var bannerIndicator: some View {
        HStack(spacing: 8.scaled) {
            ForEach(HomeFeature.banners, id: \.self) { banner in
                Circle()
                    .fill(banner == store.currentBanner ? Color(.green500) : Self.inactiveIndicatorColor)
                    .frame(width: 8.scaled, height: 8.scaled)
            }
        }
    }
    
    private var recordButton: some View {
        PlobbyButton(text: store.currentBanner.recordButtonTitle) {
            store.send(.recordButtonTapped)
        }
        .padding(.bottom, 4.scaled)
    }
}

// MARK: - 새로 올라온 기록

extension HomeView {

    private var recentRecordSection: some View {
        VStack(spacing: 0) {
            recentRecordHeader
            recentRecordList
        }
        .padding(.top, 40.scaled)
    }

    /// - 가로 배치 카드
    private func recentRecordCard(_ record: RecordSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            recentRecordCardImage(record)

            recentRecordTitle(record)
                .padding(.top, 8.scaled)

            recentRecordMeta(record)
                .padding(.top, 10.scaled)

            recentRecordAuthor(record)
                .padding(.top, 8.scaled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// - 세로 배치 행
    private func recentRecordRow(_ record: RecordSummary) -> some View {
        HStack(spacing: 16.scaled) {
            VStack(alignment: .leading, spacing: 0) {
                recentRecordTitle(record)

                recentRecordMeta(record)
                    .padding(.top, 10.scaled)

                recentRecordAuthor(record)
                    .padding(.top, 8.scaled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            recentRecordRowImage(record)
        }
        .padding(.vertical, 13.scaled)
    }

    private func recentRecordCardImage(_ record: RecordSummary) -> some View {
        Color.clear
            .aspectRatio(175 / 132, contentMode: .fit)
            .overlay {
                recordPhoto(record.coverPhotoURL)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
    }

    private func recentRecordRowImage(_ record: RecordSummary) -> some View {
        recordPhoto(record.coverPhotoURL)
            .frame(width: 76.scaled, height: 76.scaled)
            .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
    }

    /// 대표 사진. 불러오는 중이거나 사진이 없으면 회색 배경을 보여줘요
    private func recordPhoto(_ url: URL?) -> some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Color(.gray50)
        }
    }

    private func recentRecordTitle(_ record: RecordSummary) -> some View {
        Text(record.title)
            .plobbyFont(.actionLabel)
            .foregroundStyle(Color(.textPrimary))
            .lineLimit(1)
    }

    private func recentRecordMeta(_ record: RecordSummary) -> some View {
        HStack(spacing: 8.scaled) {
            Text(record.createdAt, format: .relative(presentation: .named))

            HStack(spacing: 2.scaled) {
                Image(systemName: "heart")
                Text("\(record.likeCount)")
            }
        }
        .plobbyFont(.metadata)
        .foregroundStyle(Color(.gray600))
    }

    private func recentRecordAuthor(_ record: RecordSummary) -> some View {
        HStack(spacing: 6.scaled) {
            AsyncImage(url: record.profileImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
            }
            .frame(width: 16.scaled, height: 16.scaled)
            .clipShape(Circle())

            Text(record.nickname)
                .plobbyFont(.metadata)
                .padding(.leading, 4.scaled)
        }
        .foregroundStyle(Color(.gray600))
    }
}

extension HomeView {
    
    // TODO: 컬러셋 확정 후 교체 (#E1E7E4)
    private static let dividerColor = Color(red: 0xE1 / 255, green: 0xE7 / 255, blue: 0xE4 / 255)

    private var recentRecordHeader: some View {
        HStack {
            Text("새로 올라온 기록")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Spacer()
        }
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 16.scaled)
    }
    
    private var recentRecordList: some View {
        HStack(alignment: .top, spacing: 12.scaled) {
            ForEach(store.recentRecordCards) { record in
                Button {
                    store.send(.recentRecordTapped(record.id))
                } label: {
                    recentRecordCard(record)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20.scaled)
    }

    private var recentRecordRowList: some View {
        VStack(spacing: 0) {
            ForEach(store.recentRecordRows) { record in
                Button {
                    store.send(.recentRecordTapped(record.id))
                } label: {
                    recentRecordRow(record)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if record.id != store.recentRecordRows.last?.id {
                    Divider()
                        .overlay(Self.dividerColor)
                }
            }
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 12.scaled)
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
                            .plobbyFont(.metadata)
                            .foregroundStyle(Color(.textSecondary))
                            .padding(.top, 22.scaled)
                            .padding(.leading, 20.scaled)
                            .padding(.bottom, 8.scaled)

                        Text("바다도 사막화가\n된다고?")
                            .plobbyFont(.heading)
                            .foregroundStyle(Color(.textPrimary))
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 20.scaled)
                            .padding(.bottom, 22.scaled)
                    }
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20.scaled)
        .padding(.top, 24.scaled)
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
