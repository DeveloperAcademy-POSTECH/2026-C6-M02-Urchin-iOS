//
//  MainTabView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct MainTabView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<MainTabFeature>

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $store.scope(state: \.map.path, action: \.map.path)) {
            tabView
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(
                    item: $store.scope(state: \.home.recordDetail, action: \.home.recordDetail)
                ) { store in
                    RecordDetailView(store: store)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .navigationDestination(
                    item: $store.scope(state: \.home.notification, action: \.home.notification)
                ) { store in
                    NotificationView(store: store)
                }
                .navigationDestination(
                    item: $store.scope(state: \.home.goalList, action: \.home.goalList)
                ) { store in
                    GoalListView(store: store)
                }
                .navigationDestination(
                    item: $store.scope(state: \.home.userHome, action: \.home.userHome)
                ) { store in
                    UserHomeView(store: store)
                }
                .navigationDestination(
                    item: $store.scope(state: \.collection.my, action: \.collection.my)
                ) { store in
                    myView(store: store)
                }
        } destination: { store in
            MapView.destination(store)
                .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.primary)
        .background {
            GuestTapInterceptor(isEnabled: isGuestTapIntercepted) {
                store.send(.loginSheetPresentationChanged(true))
            }
        }
        .overlay {
            if store.isLoginSheetPresented {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        store.send(.loginSheetPresentationChanged(false))
                    }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isLoginSheetPresented)
        .fullScreenCover(item: $store.scope(state: \.recordFlow, action: \.recordFlow)) { store in
            RecordView(store: store)
        }
        .sheet(isPresented: $store.isLoginSheetPresented.sending(\.loginSheetPresentationChanged)) {
            LoginRequiredSheet(
                isSigningIn: store.signIn.isSigningIn,
                onAppleLogin: { store.send(.appleLoginButtonTapped) },
                onBrowse: { store.send(.loginSheetPresentationChanged(false)) }
            )
        }
        .plobbyAlert(store: store, state: \.signIn.alert, action: \.signIn.alert)
    }
}

// MARK: - Subviews

private extension MainTabView {

    /// 비회원은 탭 화면에서 무엇을 눌러도 로그인 시트를 띄워요. 로그인 중이거나 알림이 떠 있으면 막지 않아요.
    var isGuestTapIntercepted: Bool {
        store.membershipStatus == .guest
            && !store.isLoginSheetPresented
            && !store.signIn.isSigningIn
            && store.signIn.alert == nil
    }

    var tabView: some View {
        TabView(selection: tabSelection) {
            Tab(value: .home) {
                HomeView(store: store.scope(state: \.home, action: \.home))
            } label: {
                tabLabel("홈", icon: "house", tab: .home)
            }

            Tab(value: .map) {
                MapView(store: store.scope(state: \.map, action: \.map))
            } label: {
                tabLabel("지도", icon: "map", tab: .map)
            }

            Tab(value: .collection) {
                CollectionView(store: store.scope(state: \.collection, action: \.collection))
            } label: {
                tabLabel("컬렉션", icon: "books.vertical", tab: .collection)
            }
        }
    }

    var tabSelection: Binding<MainTab> {
        Binding(
            get: { store.selectedTab },
            set: { tab in
                UIView.performWithoutAnimation {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                store.send(.tabSelected(tab))
            }
        )
    }

    func tabLabel(_ title: String, icon: String, tab: MainTab) -> some View {
        Label(title, systemImage: store.selectedTab == tab ? "\(icon).fill" : icon)
            .environment(\.symbolVariants, .none)
    }

    func myView(store: StoreOf<MyFeature>) -> some View {
        @Bindable var store = store

        return MyView(store: store)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                item: $store.scope(state: \.profileEdit, action: \.profileEdit)
            ) { store in
                ProfileEditView(store: store)
            }
            .navigationDestination(
                item: $store.scope(state: \.settings, action: \.settings)
            ) { store in
                SettingsView(store: store)
            }
            .navigationDestination(
                item: $store.scope(state: \.recordDetail, action: \.recordDetail)
            ) { store in
                RecordDetailView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .navigationDestination(
                item: $store.scope(state: \.beachHome, action: \.beachHome)
            ) { beachHomeStore in
                BeachHomeView(store: beachHomeStore)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(
                        item: $store.scope(state: \.beachRecordDetail, action: \.beachRecordDetail)
                    ) { store in
                        RecordDetailView(store: store)
                            .toolbar(.hidden, for: .navigationBar)
                    }
            }
    }
}

