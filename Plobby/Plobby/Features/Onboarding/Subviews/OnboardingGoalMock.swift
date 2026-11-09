//
//  OnboardingGoalMock.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import SwiftUI

/// 온보딩 2단계 예시 화면: 홈 화면 위에 공동 목표 카드가 겹쳐 있어요
struct OnboardingGoalMock: View {

    // MARK: - Properties

    let activity: RecordType

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            homeCard

            goalCard
                .padding(.top, 252.scaled)
        }
        .frame(width: 320.scaled, height: 388.scaled, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("공동 목표 예시 화면")
    }
}

// MARK: - 홈 카드

private extension OnboardingGoalMock {

    var homeCard: some View {
        VStack(spacing: 0) {
            HStack {
                // TODO: 로고 에셋(Outfit 폰트) 나오면 교체
                Text("plobby")
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 12.scaled))
                    .foregroundStyle(Color(.brandPrimary))

                Spacer()

                Image(.bell)
                    .resizable()
                    .frame(width: 16.scaled, height: 16.scaled)
                    .frame(width: 30.scaled, height: 30.scaled)
            }
            .padding(.leading, 16.scaled)
            .padding(.trailing, 8.scaled)
            .frame(height: 36.scaled)
            .padding(.top, 12.scaled)

            scene
        }
        .frame(width: 280.scaled, height: 280.scaled, alignment: .top)
        .onboardingMockCard(cornerRadius: 20.scaled)
    }

    // TODO: 사람·쓰레기가 있는 홈 일러스트(플로깅/플로빙) 에셋 나오면 교체. 지금은 해변 배경만 있어요
    var scene: some View {
        Image(.onboardingGoalBeach)
            .resizable()
            .scaledToFill()
            .frame(width: 280.scaled, height: 836.scaled)
            .offset(y: -46.scaled)
            .frame(width: 280.scaled, height: 232.scaled)
            .clipped()
            .overlay(alignment: .top) {
                Text("11월 4일")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 56.scaled, height: 24.scaled)
                    .background(Color(.gray0).opacity(0.95), in: Capsule())
                    .shadow(color: Color(.neutralBlack).opacity(0.1), radius: 3, y: 2)
                    .padding(.top, 12.scaled)
            }
    }
}

// MARK: - 공동 목표 카드

private extension OnboardingGoalMock {

    var goalCard: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            HStack(alignment: .top, spacing: 8.scaled) {
                VStack(alignment: .leading, spacing: 8.scaled) {
                    badges
                    titleAndInfo
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 16.scaled, weight: .medium))
                    .foregroundStyle(Color(.textSecondary))
                    .frame(width: 44.scaled, height: 44.scaled)
            }

            progress
        }
        .padding(.vertical, 12.scaled)
        .padding(.horizontal, 16.scaled)
        .frame(width: 320.scaled, height: 136.scaled, alignment: .top)
        .onboardingMockCard(cornerRadius: 16.scaled, isFloating: true)
    }

    var badges: some View {
        HStack(spacing: 8.scaled) {
            Text("공동 목표")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.textBrand))
                .padding(.horizontal, 8.scaled)
                .frame(height: 24.scaled)
                .background(Color(.surfaceBrandSubtle), in: RoundedRectangle(cornerRadius: 8.scaled))

            Text("D-7")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.textSecondary))
                .padding(.horizontal, 8.scaled)
                .frame(height: 24.scaled)
                .background(Color(.surfaceSubtle), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
    }

    var titleAndInfo: some View {
        VStack(alignment: .leading, spacing: 4.scaled) {
            Text("해양 쓰레기 줍기")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            HStack(spacing: 8.scaled) {
                infoItem(systemImage: "calendar", text: "11월 1일 ~ 11월 14일")

                Rectangle()
                    .fill(Color(.borderSubtle))
                    .frame(width: 1, height: 12.scaled)

                infoItem(systemImage: "person.fill", text: "18명 참여")
            }
        }
    }

    func infoItem(systemImage: String, text: String) -> some View {
        HStack(spacing: 4.scaled) {
            Image(systemName: systemImage)
                .font(.system(size: 14.scaled))
                .frame(width: 20.scaled, height: 20.scaled)

            Text(text)
                .plobbyFont(.helper)
        }
        .foregroundStyle(Color(.textSecondary))
    }

    var progress: some View {
        HStack(spacing: 12.scaled) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.borderDefault))

                    Capsule()
                        .fill(Color(.textBrand))
                        .frame(width: proxy.size.width * 103 / 200)
                }
            }
            .frame(height: 8.scaled)

            HStack(spacing: 4.scaled) {
                Text("103")
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textBrand))

                Text("/ 200개")
                    .plobbyFont(.label)
                    .foregroundStyle(Color(.textSecondary))
            }
            .frame(minWidth: 80.scaled, alignment: .trailing)
        }
    }
}
