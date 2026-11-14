//
//  HomeParticipantsSheet.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeParticipantsSheet: View {

    let goal: Goal
    let participants: [GoalParticipant]
    let onParticipantTapped: (GoalParticipant.ID) -> Void
    let onClose: () -> Void

    @State private var isExpanded = false
    @State private var collapsedHeight: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            summary

            if isExpanded {
                participantList
            } else {
                avatarStack
            }

            toggleButton
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 20.scaled)
        .padding(.bottom, 24.scaled)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            if !isExpanded {
                collapsedHeight = height
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([collapsedDetent, Self.expandedDetent], selection: detentBinding)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24.scaled)
        .presentationBackground(Color(.gray0))
    }
}

// MARK: - Subviews

private extension HomeParticipantsSheet {

    var collapsedDetent: PresentationDetent {
        .height(collapsedHeight ?? Self.defaultCollapsedHeight.scaled)
    }

    var detentBinding: Binding<PresentationDetent> {
        Binding(
            get: { isExpanded ? Self.expandedDetent : collapsedDetent },
            set: { isExpanded = $0 == Self.expandedDetent }
        )
    }

    var header: some View {
        HStack(spacing: 8.scaled) {
            HStack(alignment: .firstTextBaseline, spacing: 8.scaled) {
                Text("함께한 사람")
                    .plobbyFont(.heading)
                    .foregroundStyle(Color(.textPrimary))

                Text("\(participants.count)명")
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(Color(.currentBrandText))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HomeSheetCloseButton(action: onClose)
        }
    }

    var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(goal.periodText)
                .plobbyFont(.label)
                .foregroundStyle(Color(.textSecondary))
                .padding(.bottom, 16.scaled)

            HStack(spacing: 8.scaled) {
                VStack(alignment: .leading, spacing: 4.scaled) {
                    Text("함께 모은 쓰레기")
                        .plobbyFont(.actionLabel)
                        .foregroundStyle(Color(.textPrimary))

                    Text("플로깅, 플로빙 합산")
                        .plobbyFont(.label)
                        .foregroundStyle(Color(.textSecondary))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(goal.collectedCount)개")
                    .plobbyFont(.metric)
                    .foregroundStyle(Color(.currentBrandText))
            }
            .padding(.horizontal, 16.scaled)
            .padding(.vertical, 12.scaled)
            .background(
                Color(.currentBrandSubtle),
                in: RoundedRectangle(cornerRadius: 12.scaled)
            )
        }
    }

    /// 목록 앞에서부터 몇 명의 프로필 사진과 나머지 인원 수예요.
    var avatarStack: some View {
        HStack(spacing: 8.scaled) {
            ForEach(participants.prefix(Self.previewCount)) { participant in
                HomeParticipantAvatar(participant: participant)
            }

            if participants.count > Self.previewCount {
                Text("+\(participants.count - Self.previewCount)")
                    .plobbyFont(.labelSelected)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 36.scaled, height: 36.scaled)
                    .background(Color(.gray50), in: Circle())
            }
        }
        .padding(.top, 16.scaled)
        .padding(.bottom, 4.scaled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("함께한 사람 \(participants.count)명")
    }

    var participantList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(participants) { participant in
                    HomeParticipantRow(participant: participant, showsDivider: participant.id != participants.last?.id) {
                        onParticipantTapped(participant.id)
                    }
                }
            }
            .padding(.top, 8.scaled)
        }
        .scrollIndicators(.hidden)
    }

    var toggleButton: some View {
        Button {
            isExpanded.toggle()
        } label: {
            Text(isExpanded ? "간단히 보기" : "참여자 모두 보기")
                .plobbyFont(.labelSelected)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity)
                .frame(height: 44.scaled)
                .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
        .buttonStyle(.plain)
        .padding(.top, 12.scaled)
    }
}

// MARK: - Constants

private extension HomeParticipantsSheet {

    static let previewCount = 3
    static let expandedDetent = PresentationDetent.height(668.scaled)
    static let defaultCollapsedHeight: CGFloat = 308
}

// MARK: - Row

struct HomeParticipantRow: View {

    let participant: GoalParticipant
    var showsDivider = true
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12.scaled) {
                HomeParticipantAvatar(participant: participant)

                Text(participant.isBlocked ? "차단한 회원" : participant.nickname)
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textPrimary))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8.scaled)
            .overlay(alignment: .bottom) {
                if showsDivider {
                    Rectangle()
                        .fill(Color(.gray200))
                        .frame(height: 1.scaled)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!participant.isBlocked)
        .accessibilityLabel(participant.isBlocked ? "차단한 회원" : participant.nickname)
    }
}

// MARK: - Avatar

struct HomeParticipantAvatar: View {

    let participant: GoalParticipant

    var body: some View {
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
                        .font(.system(size: 20.scaled, weight: .bold))
                        .foregroundStyle(Color(.gray400))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.gray100))
                }
            }
        }
        .frame(width: 36.scaled, height: 36.scaled)
        .clipShape(Circle())
    }
}
