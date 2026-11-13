//
//  NotificationView.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct NotificationView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<NotificationFeature>

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlobbyNavigationBar(title: "알림", style: .leading) {
                store.send(.backButtonTapped)
            }

            content
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
        .navigationDestination(item: $store.scope(state: \.recordDetail, action: \.recordDetail)) { store in
            RecordDetailView(store: store)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Subviews

extension NotificationView {

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.isEmpty {
            emptyView
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    markAllAsReadButton
                    notificationSection("오늘", notifications: store.todayNotifications)

                    if !store.todayNotifications.isEmpty, !store.earlierNotifications.isEmpty {
                        Color(.gray50)
                            .frame(height: 16)
                    }

                    notificationSection("이전", notifications: store.earlierNotifications)
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await store.send(.refreshed).finish()
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16.scaled) {
            VStack(spacing: 12.scaled) {
                Text("새로운 알림이 없습니다")
                    .plobbyFont(.cardTitle)
                    .foregroundStyle(Color(.textPrimary))

                Text("내 기록에 받은 좋아요와 관심 바다의 새 기록을\n여기서 알려드려요. 알림 설정을 켜보세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textTertiary))
                    .multilineTextAlignment(.center)
            }

            settingsButton
        }
        .padding(.horizontal, 20.scaled)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var settingsButton: some View {
        Button {
            store.send(.settingsButtonTapped)
        } label: {
            Text("알림 설정")
                .plobbyFont(.label)
                .foregroundStyle(Color(.green500))
                .padding(.horizontal, 16.scaled)
                .padding(.vertical, 8.scaled)
                .overlay {
                    RoundedRectangle(cornerRadius: 10.scaled)
                        .stroke(Color(.green500), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var markAllAsReadButton: some View {
        Button {
            store.send(.markAllAsReadButtonTapped)
        } label: {
            Text("모두 읽음")
                .plobbyFont(.label)
                .foregroundStyle(store.hasUnread ? Color(.gray700) : Color(.textDisabled))
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!store.hasUnread)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func notificationSection(_ title: String, notifications: [AppNotification]) -> some View {
        if !notifications.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 16))
                    .foregroundStyle(Color(.textPrimary))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                ForEach(notifications) { notification in
                    notificationRow(notification)

                    if notification.id != notifications.last?.id {
                        Color(.gray100)
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    private func notificationRow(_ notification: AppNotification) -> some View {
        Button {
            store.send(.notificationTapped(notification))
        } label: {
            HStack(alignment: .top, spacing: 16) {
                kindIcon(notification.kind)

                VStack(alignment: .leading, spacing: 8) {
                    Text(notification.title)
                        .plobbyFont(.notification)
                        .foregroundStyle(Color(.textPrimary))

                    Text(notification.subtitle)
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.textSecondary))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(timeText(notification.createdAt))
                    .plobbyFont(.metadata)
                    .foregroundStyle(notification.isRead ? Color(.textTertiary) : Color(.green600))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(notification.isRead ? Color(.gray0) : Color(.currentBrandSubtle))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func kindIcon(_ kind: AppNotification.Kind) -> some View {
        Image(systemName: kind.iconName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color(.green600))
            .frame(width: 24, height: 24)
    }

    private func timeText(_ date: Date) -> String {
        guard Calendar.current.isDateInToday(date) else {
            let components = Calendar.current.dateComponents([.month, .day], from: date)
            return "\(components.month ?? 0)월 \(components.day ?? 0)일"
        }

        let minutes = Int(Date.now.timeIntervalSince(date) / 60)

        switch minutes {
        case ..<1: return "방금 전"
        case ..<60: return "\(minutes)분 전"
        default: return "\(minutes / 60)시간 전"
        }
    }
}

// MARK: - AppNotification.Kind+

private extension AppNotification.Kind {

    var iconName: String {
        switch self {
        case .like: "heart.fill"
        case .newRecordAtFavoriteBeach: "water.waves"
        case .reportRemoved: "light.beacon.max.fill"
        case .goalAchieved: "flag.fill"
        }
    }
}
