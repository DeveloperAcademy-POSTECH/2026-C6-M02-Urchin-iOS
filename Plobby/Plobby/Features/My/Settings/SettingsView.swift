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
    /// 마이 화면에 목록만 넣을 때는 상단 바를 숨겨요
    var showsNavigationBar = true
    @Environment(\.openURL) private var openURL

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsNavigationBar {
                navigationBar
                    .padding(.horizontal, 20)
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
                .toolbar(.hidden, for: .tabBar)
        }
        .navigationDestination(item: $store.scope(state: \.blockedUsers, action: \.blockedUsers)) { store in
            BlockedUsersView(store: store)
                .toolbar(.hidden, for: .tabBar)
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Subviews

extension SettingsView {

    private var navigationBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                store.send(.backButtonTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 32, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.isSigningOut)
            .accessibilityLabel("뒤로")

            Text("설정")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 56)
    }

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
                            .foregroundStyle(Color(.textTertiary))
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
                        .foregroundStyle(Color(.textTertiary))
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
                    .foregroundStyle(Color(.textSecondary))
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
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.textTertiary))
                .padding(.bottom, 4)

            content()
        }
    }

    private func rowTitle(_ title: String, color: Color = Color(.textPrimary)) -> some View {
        Text(title)
            .plobbyFont(.body)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
