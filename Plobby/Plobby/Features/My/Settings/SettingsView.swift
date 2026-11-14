//
//  SettingsView.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct SettingsView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SettingsFeature>
    @Environment(\.openURL) private var openURL

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlobbyNavigationBar(
                title: "설정",
                style: .leading,
                isBackEnabled: !store.isSigningOut
            ) {
                store.send(.backButtonTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    notificationSection
                    serviceSection
                    manageUserSection
                    accountSection
                    infoSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.gray0))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
        .navigationDestination(item: $store.scope(state: \.withdrawal, action: \.withdrawal)) { store in
            WithdrawalView(store: store)
        }
        .navigationDestination(item: $store.scope(state: \.blockedUsers, action: \.blockedUsers)) { store in
            BlockedUsersView(store: store)
        }
        .plobbyAlert(store: store, state: \.alert, action: \.alert)
    }
}

// MARK: - Subviews

extension SettingsView {

    private var notificationSection: some View {
        section("알림과 권한") {
            Toggle(isOn: $store.isNotificationEnabled.sending(\.notificationToggled)) {
                rowTitle("알림 설정")
            }
            .tint(Color(.green500))
            .frame(height: 52)
        }
    }

    private var serviceSection: some View {
        section("서비스 안내") {
            ForEach(ServiceLink.allCases, id: \.self) { link in
                Button {
                    guard let url = link.url else { return }

                    openURL(url)
                } label: {
                    HStack(alignment: .center, spacing: 0) {
                        rowTitle(link.title)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.currentNeutralGray)
                    }
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var manageUserSection: some View {
        section("사용자 관리") {
            Button {
                store.send(.manageUserTapped)
            } label: {
                HStack(alignment: .center, spacing: 0) {
                    rowTitle("차단한 사용자")

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(height: 52)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var accountSection: some View {
        section("계정") {
            Button {
                store.send(.logoutButtonTapped)
            } label: {
                rowTitle("로그아웃")
                    .frame(height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.isSigningOut)

            Button {
                store.send(.withdrawalButtonTapped)
            } label: {
                rowTitle("회원 탈퇴", color: Color(.currentError))
                    .frame(height: 52)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var infoSection: some View {
        section("정보") {
            HStack(alignment: .center, spacing: 0) {
                rowTitle("앱 버전")

                Text(store.appVersion)
                    .plobbyFont(.body)
                    .foregroundStyle(Color.textTertiary)
            }
            .frame(height: 52)
        }
    }

    private func section(
        _ title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .plobbyFont(.label)
                .foregroundStyle(Color(.gray600))
                .padding(.bottom, 4)

            content()
        }
    }

    private func rowTitle(_ title: String, color: Color = .textPrimary) -> some View {
        Text(title)
            .plobbyFont(.actionLabel)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
