//
//  OnboardingMapMock.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import SwiftUI

/// 온보딩 3단계 예시 화면: 지도 탭 화면을 줄여서 보여줘요
struct OnboardingMapMock: View {

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(.onboardingMap)
                .resizable()
                .scaledToFill()
                .frame(width: 454.scaled, height: 988.scaled)
                .offset(x: -55.scaled, y: -379.scaled)

            searchBar
                .padding(.top, 12.scaled)
                .padding(.leading, 16.scaled)

            favoriteChips
                .padding(.top, 66.scaled)
                .padding(.leading, 15.scaled)

            marker
                .padding(.top, 280.scaled)
                .padding(.leading, 64.scaled)

            locationButton
                .padding(.top, 316.scaled)
                .padding(.leading, 268.scaled)

            tabBar
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 16.scaled)
                .padding(.bottom, 12.scaled)
        }
        .frame(width: 320.scaled, height: 432.scaled, alignment: .topLeading)
        .onboardingMockCard(cornerRadius: 20.scaled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("지도 예시 화면")
    }
}

// MARK: - 검색창, 관심 해변

private extension OnboardingMapMock {

    var searchBar: some View {
        HStack(spacing: 8.scaled) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13.scaled))
                .frame(width: 20.scaled, height: 20.scaled)

            Rectangle()
                .fill(Color(.textPrimary))
                .frame(width: 1, height: 16.scaled)

            Text("해변 이름을 입력해 주세요")
                .plobbyFont(.helper)
        }
        .foregroundStyle(Color(.gray600))
        .padding(.horizontal, 8.scaled)
        .frame(width: 288.scaled, height: 44.scaled, alignment: .leading)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: CGFloat(9.5).scaled))
    }

    var favoriteChips: some View {
        HStack(spacing: 4.scaled) {
            ForEach(["송도 해수욕장", "부산 송도 해수욕장", "안목 해변"], id: \.self) { name in
                HStack(spacing: 4.scaled) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 5.scaled, weight: .medium))
                        .foregroundStyle(Color(.gray0))
                        .frame(width: 12.scaled, height: 12.scaled)
                        .background(Color(.brandPrimary), in: Circle())

                    Text(name)
                        .plobbyFont(.metadata)
                        .foregroundStyle(Color(.textPrimary))
                }
                .padding(4.scaled)
                .background(Color(.gray0), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color(.borderSubtle), lineWidth: 0.8)
                }
            }
        }
    }
}

// MARK: - 마커, 현재 위치

private extension OnboardingMapMock {

    var marker: some View {
        Image(.mapMarkerBag)
            .resizable()
            .scaledToFit()
            .frame(width: 24.scaled, height: 24.scaled)
            .frame(width: 56.scaled, height: 56.scaled)
            .background(Color(.gray0), in: Circle())
            .shadow(color: Color(.neutralBlack).opacity(0.25), radius: 1.5, y: 3)
            .overlay(alignment: .topTrailing) {
                Text("29")
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.gray0))
                    .frame(width: 40.scaled, height: 28.scaled)
                    .background(Color(.textPrimary), in: Capsule())
                    .offset(x: 20.scaled, y: -8.scaled)
            }
    }

    var locationButton: some View {
        Image(systemName: "scope")
            .font(.system(size: 17.scaled))
            .foregroundStyle(Color(.textPrimary))
            .frame(width: 36.scaled, height: 36.scaled)
            .background(Color(.gray0), in: Circle())
            .shadow(color: Color(.neutralBlack).opacity(0.25), radius: 1, y: 1)
    }
}

// MARK: - 탭바

private extension OnboardingMapMock {

    var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(systemImage: "house", title: "홈", isSelected: false)
            tabItem(systemImage: "map.fill", title: "지도", isSelected: true)
            tabItem(systemImage: "books.vertical", title: "컬렉션", isSelected: false)
        }
        .padding(4.scaled)
        .background(Color(.gray0), in: Capsule())
        .shadow(color: Color(.neutralBlack).opacity(0.1), radius: 8, y: 2)
    }

    func tabItem(systemImage: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 2.scaled) {
            Image(systemName: systemImage)
                .font(.system(size: 17.scaled))

            Text(title)
                .font(.system(size: 8.scaled, weight: .medium))
        }
        .foregroundStyle(Color(.textPrimary))
        .frame(maxWidth: .infinity)
        .frame(height: 44.scaled)
        .background(isSelected ? Color(.gray100) : .clear, in: Capsule())
    }
}
