//
//  OnboardingRecordMock.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import SwiftUI

/// 온보딩 1단계 예시 화면: 기록 상세 카드 위에 수거한 쓰레기 카드가 겹쳐 있어요
struct OnboardingRecordMock: View {

    // MARK: - Properties

    let activity: RecordType

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            recordDetailCard

            trashSummaryCard
                .padding(.top, 244.scaled)
        }
        .frame(width: 320.scaled, height: 388.scaled, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("기록 상세 예시 화면")
    }
}

// MARK: - 기록 상세 카드

private extension OnboardingRecordMock {

    var recordDetailCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            navigationBar

            VStack(alignment: .leading, spacing: 8.scaled) {
                author

                Text("함덕해수욕장 \(activity.name) 기록")
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textPrimary))

                photo
            }
            .padding(.top, 16.scaled)
            .padding(.horizontal, 16.scaled)
        }
        .padding(.top, 11.scaled)
        .frame(width: 280.scaled, height: 280.scaled, alignment: .top)
        .onboardingMockCard(cornerRadius: 20.scaled)
    }

    var navigationBar: some View {
        HStack(spacing: 0) {
            Image(systemName: "chevron.left")
                .font(.system(size: 10.scaled, weight: .medium))
                .frame(width: 32.scaled, height: 32.scaled)

            Text("기록 상세")
                .plobbyFont(.labelSelected)
                .frame(maxWidth: .infinity)

            Image(systemName: "ellipsis")
                .font(.system(size: 13.scaled, weight: .medium))
                .frame(width: 32.scaled, height: 32.scaled)
        }
        .foregroundStyle(Color(.textPrimary))
        .frame(height: 40.scaled)
        .padding(.horizontal, 16.scaled)
    }

    var author: some View {
        HStack(spacing: 4.scaled) {
            Image(.onboardingProfile)
                .resizable()
                .scaledToFill()
                .frame(width: 24.scaled, height: 24.scaled)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2.scaled) {
                Text("바다지기")
                Text("1일 전")
            }
            .plobbyFont(.metadata)
            .foregroundStyle(Color(.textSecondary))
        }
    }

    var photo: some View {
        Image(activity.onboardingPhoto)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 156.scaled)
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    Image(systemName: "heart")
                        .font(.system(size: 17.scaled, weight: .medium))
                        .frame(width: 32.scaled, height: 32.scaled)

                    Text("24")
                        .plobbyFont(.metadata)
                }
                .foregroundStyle(Color(.gray0))
                .padding(.trailing, 8.scaled)
            }
            .overlay(alignment: .topTrailing) {
                // 플로빙 예시는 사진이 여러 장이라 장수를 보여줘요
                if activity == .plobbing {
                    Text("1/2")
                        .plobbyFont(.metadata)
                        .foregroundStyle(Color(.gray0))
                        .frame(width: 32.scaled, height: 20.scaled)
                        .background(Color(.neutralBlack).opacity(0.6), in: RoundedRectangle(cornerRadius: CGFloat(5.5).scaled))
                        .padding(8.scaled)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.scaled))
    }
}

// MARK: - 수거한 쓰레기 카드

private extension OnboardingRecordMock {

    static let trashRows: [(name: String, count: Int)] = [
        ("낚시·어업 용품", 6),
        ("플라스틱", 5),
        ("캔", 3)
    ]

    var trashSummaryCard: some View {
        VStack(spacing: 4.scaled) {
            HStack {
                Text("수거한 쓰레기")
                    .plobbyFont(.actionLabel)

                Spacer()

                Text("14개")
                    .plobbyFont(.heading)
            }
            .frame(height: 32.scaled)

            VStack(spacing: 0) {
                ForEach(Self.trashRows, id: \.name) { row in
                    HStack {
                        Text(row.name)
                        Spacer()
                        Text("\(row.count)개")
                    }
                    .plobbyFont(.label)
                    .frame(height: 28.scaled)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color(.borderDefault))
                            .frame(height: 1)
                    }
                }
            }
        }
        .foregroundStyle(Color(.textPrimary))
        .padding(.top, 11.scaled)
        .padding(.horizontal, 15.scaled)
        .frame(width: 320.scaled, height: 144.scaled, alignment: .top)
        .onboardingMockCard(cornerRadius: 16.scaled, isFloating: true)
    }
}

// MARK: - 공통 카드 모양

extension View {

    /// 온보딩 예시 화면 카드: 흰 배경, 테두리, 그림자.
    /// 위에 겹친 카드(isFloating)는 그림자를 더 진하게 줘서 떠 보이게 해요
    func onboardingMockCard(cornerRadius: CGFloat, isFloating: Bool = false) -> some View {
        background(Color(.backgroundDefault))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color(.borderDefault), lineWidth: 1)
            }
            .shadow(
                color: Color(.textPrimary).opacity(isFloating ? 0.1 : 0.06),
                radius: isFloating ? 10 : 6,
                y: isFloating ? 8 : 4
            )
    }
}

// MARK: - RecordType

private extension RecordType {

    var onboardingPhoto: ImageResource {
        switch self {
        case .plogging: .onboardingRecordPlogging
        case .plobbing: .onboardingRecordPlobbing
        }
    }
}
