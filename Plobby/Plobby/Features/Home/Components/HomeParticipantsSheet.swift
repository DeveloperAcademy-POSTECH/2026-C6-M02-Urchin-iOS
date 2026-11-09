//
//  HomeParticipantsSheet.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 해당 활동을 함께한 사람을 수거량 순으로 보여주는 시트예요.
/// 처음에는 상위 몇 명만 보여주고, "전체 보기"를 누르면 시트가 커지며 모두 보여줘요.
struct HomeParticipantsSheet: View {

    let board: HomeGoalBoard
    let now: Date
    let onParticipantTapped: (HomeGoalParticipant.ID) -> Void
    let onClose: () -> Void

    @State private var detent: PresentationDetent = Self.collapsedDetent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            summary
            participantList
            toggleButton
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 28.scaled)
        .padding(.bottom, 24.scaled)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([Self.collapsedDetent, Self.expandedDetent], selection: $detent)
        .presentationCornerRadius(24.scaled)
        .presentationBackground(Color(.gray0))
    }
}

// MARK: - Subviews

private extension HomeParticipantsSheet {

    var isExpanded: Bool {
        detent == Self.expandedDetent
    }

    var header: some View {
        HStack(spacing: 8.scaled) {
            Text("\(board.goal.recordType.name)에 함께한 사람")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            HomeSheetCloseButton(action: onClose)
        }
    }

    var summary: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text(periodText)
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))

            HStack(spacing: 18.scaled) {
                statistic(
                    value: "\(board.participantCount)명",
                    title: "참여",
                    valueColor: Color(.textPrimary)
                )
                statistic(
                    value: "\(board.participantCollectedCount)개",
                    title: "누적 수거",
                    valueColor: Color(.currentBrandText)
                )
            }
            .padding(.vertical, 15.scaled)
        }
    }

    func statistic(value: String, title: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2.scaled) {
            Text(value)
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 28.scaled))
                .foregroundStyle(valueColor)

            Text(title)
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 13.scaled))
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var participantList: some View {
        let participants = board.rankedParticipants

        if isExpanded {
            ScrollView {
                rows(participants)
            }
            .scrollIndicators(.hidden)
        } else {
            rows(Array(participants.prefix(Self.collapsedCount)))
        }
    }

    func rows(_ participants: [HomeRankedParticipant]) -> some View {
        VStack(spacing: 0) {
            ForEach(participants) { ranked in
                HomeParticipantRow(ranked: ranked) {
                    onParticipantTapped(ranked.participant.id)
                }
            }
        }
    }

    var toggleButton: some View {
        Button {
            detent = isExpanded ? Self.collapsedDetent : Self.expandedDetent
        } label: {
            Text(isExpanded ? "간단히 보기" : "전체 보기")
                .plobbyFont(.labelSelected)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity)
                .frame(height: 44.scaled)
                .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
        .buttonStyle(.plain)
        .padding(.top, 8.scaled)
    }

    /// "11월 1일~10일"처럼 목표 시작일부터 오늘(또는 종료일)까지예요.
    var periodText: String {
        let goal = board.goal
        let end = min(now, goal.endsAt)
        let calendar = Calendar(identifier: .gregorian)
        let sameMonth = calendar.component(.month, from: goal.startsAt) == calendar.component(.month, from: end)
        let endText = sameMonth ? "\(calendar.component(.day, from: end))일" : end.homeMonthDayText
        return "\(goal.startsAt.homeMonthDayText)~\(endText)"
    }
}

// MARK: - Constants

private extension HomeParticipantsSheet {

    /// 접었을 때 보여줄 사람 수예요.
    static let collapsedCount = 4
    /// 피그마 시트 높이(458, 662)에서 홈 인디케이터 영역을 뺀 높이예요.
    static let collapsedDetent = PresentationDetent.height(424.scaled)
    static let expandedDetent = PresentationDetent.height(628.scaled)
}

// MARK: - Row

/// 순위·프로필·닉네임·수거량 한 줄이에요. 차단한 사용자는 가려서 보여주고 누를 수 없어요.
struct HomeParticipantRow: View {

    let ranked: HomeRankedParticipant
    let onTap: () -> Void

    private var participant: HomeGoalParticipant { ranked.participant }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8.scaled) {
                HStack(spacing: 12.scaled) {
                    avatar

                    Text(participant.isBlocked ? "차단한 회원" : participant.nickname)
                        .plobbyFont(.body)
                        .foregroundStyle(Color(.textPrimary))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("\(participant.collectedCount)개")
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textPrimary))
            }
            .padding(.vertical, 8.scaled)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Color(.gray200))
                    .frame(height: 1.scaled)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 차단한 사용자는 흐리게 바꾸지 않고 누르기만 막아요.
        .allowsHitTesting(!participant.isBlocked)
        .accessibilityLabel(accessibilityText)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if participant.isBlocked {
                    Image(systemName: "nosign")
                        .font(.system(size: 20.scaled, weight: .medium))
                        .foregroundStyle(Color(.gray400))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.gray100))
                } else {
                    AsyncImage(url: participant.profileImageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16.scaled))
                            .foregroundStyle(Color(.gray400))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.gray100))
                    }
                }
            }
            .frame(width: 34.scaled, height: 34.scaled)
            .clipShape(Circle())

            if showsRankBadge {
                Text("\(ranked.rank)위")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.currentBrandText))
                    .padding(.horizontal, 4.scaled)
                    .frame(height: 16.scaled)
                    .background(Color(.gray50), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color(.gray0), lineWidth: 1)
                    }
                    .fixedSize()
                    .offset(x: 8.scaled, y: 4.scaled)
            }
        }
        .frame(width: 34.scaled, height: 34.scaled)
    }

    /// 1~3위만 순위 배지를 달아요.
    private var showsRankBadge: Bool {
        ranked.rank <= 3 && !participant.isBlocked
    }

    private var accessibilityText: String {
        let name = participant.isBlocked ? "차단한 회원" : participant.nickname
        return "\(ranked.rank)위 \(name), \(participant.collectedCount)개"
    }
}

// MARK: - Close Button

/// 시트·팝업 오른쪽 위 닫기 버튼이에요.
struct HomeSheetCloseButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16.scaled, weight: .semibold))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 44.scaled, height: 44.scaled)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
    }
}
