//
//  HomeParticipantsSheet.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeParticipantsSheet: View {

    let board: HomeGoalBoard
    let now: Date
    let onParticipantTapped: (GoalParticipant.ID) -> Void
    let onClose: () -> Void

    @State private var isExpanded = false
    @State private var collapsedHeight: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            summary
            participantList

            if hasMore {
                toggleButton
            }
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 28.scaled)
        .padding(.bottom, 24.scaled)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            if !isExpanded {
                collapsedHeight = height
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents(detents, selection: detentBinding)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24.scaled)
        .presentationBackground(Color(.gray0))
    }
}

// MARK: - Subviews

private extension HomeParticipantsSheet {

    var hasMore: Bool {
        board.rankedParticipants.count > Self.collapsedCount
    }

    var collapsedDetent: PresentationDetent {
        .height(collapsedHeight ?? Self.defaultCollapsedHeight.scaled)
    }

    var detents: Set<PresentationDetent> {
        hasMore ? [collapsedDetent, Self.expandedDetent] : [collapsedDetent]
    }

    var detentBinding: Binding<PresentationDetent> {
        Binding(
            get: { isExpanded ? Self.expandedDetent : collapsedDetent },
            set: { isExpanded = $0 == Self.expandedDetent }
        )
    }

    var header: some View {
        HStack(spacing: 8.scaled) {
            Text("\(board.recordType.name)에 함께한 사람")
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
                HomeParticipantRow(ranked: ranked, showsDivider: ranked.id != participants.last?.id) {
                    onParticipantTapped(ranked.participant.id)
                }
            }
        }
    }

    var toggleButton: some View {
        Button {
            isExpanded.toggle()
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

    var periodText: String {
        let goal = board.goal
        let end = min(now, goal.lastDay)
        let calendar = Calendar(identifier: .gregorian)
        let sameMonth = calendar.component(.month, from: goal.startsAt) == calendar.component(.month, from: end)
        let endText = sameMonth ? "\(calendar.component(.day, from: end))일" : end.homeMonthDayText
        return "\(goal.startsAt.homeMonthDayText)~\(endText)"
    }
}

// MARK: - Constants

private extension HomeParticipantsSheet {

    static let collapsedCount = 3
    static let expandedDetent = PresentationDetent.height(628.scaled)
    static let defaultCollapsedHeight: CGFloat = 424
}

// MARK: - Row

struct HomeParticipantRow: View {

    let ranked: HomeRankedParticipant
    var showsDivider = true
    let onTap: () -> Void

    private var participant: GoalParticipant { ranked.participant }

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
                if showsDivider {
                    Capsule()
                        .fill(Color(.gray200))
                        .frame(height: 1.scaled)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private var showsRankBadge: Bool {
        ranked.rank <= 3 && !participant.isBlocked
    }

    private var accessibilityText: String {
        let name = participant.isBlocked ? "차단한 회원" : participant.nickname
        return "\(ranked.rank)위 \(name), \(participant.collectedCount)개"
    }
}
