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
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            Tab(value: .home) {
                NavigationStack {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(
                            item: $store.scope(state: \.home.recordDetail, action: \.home.recordDetail)
                        ) { store in
                            RecordDetailView(store: store)
                                .toolbar(.hidden, for: .navigationBar)
                                .toolbar(.hidden, for: .tabBar)
                        }
                        .navigationDestination(
                            item: $store.scope(state: \.home.notification, action: \.home.notification)
                        ) { store in
                            NotificationView(store: store)
                                .toolbar(.hidden, for: .tabBar)
                        }
                        .navigationDestination(
                            item: $store.scope(state: \.home.goalList, action: \.home.goalList)
                        ) { store in
                            GoalListView(store: store)
                                .toolbar(.hidden, for: .tabBar)
                        }
                }
            } label: {
                tabLabel("홈", icon: "house", tab: .home)
            }

            Tab(value: .map) {
                MapView(store: store.scope(state: \.map, action: \.map))
            } label: {
                tabLabel("지도", icon: "map", tab: .map)
            }

            Tab(value: .collection) {
                NavigationStack {
                    CollectionView(store: store.scope(state: \.collection, action: \.collection))
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(
                            item: $store.scope(state: \.collection.my, action: \.collection.my)
                        ) { store in
                            myView(store: store)
                        }
                }
            } label: {
                tabLabel("컬렉션", icon: "books.vertical", tab: .collection)
            }
        }
        .tint(.primary)
        .overlay(alignment: .bottomTrailing) {
            if store.isRecordMenuPresented {
                recordMenu
            }
        }
        .animation(.spring(duration: 0.25), value: store.isRecordMenuPresented)
        .fullScreenCover(item: $store.scope(state: \.recordFlow, action: \.recordFlow)) { store in
            RecordView(store: store)
        }
        .plobbyBottomSheet(isPresented: $store.isLoginSheetPresented.sending(\.loginSheetPresentationChanged)) {
            LoginRequiredSheet(
                isSigningIn: store.signIn.isSigningIn,
                onAppleLogin: { store.send(.appleLoginButtonTapped) },
                onBrowse: { store.send(.loginSheetPresentationChanged(false)) }
            )
        }
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
    }
}

// MARK: - Subviews

extension MainTabView {

    /// 선택된 탭만 채워진 아이콘을 보여줘요
    private func tabLabel(_ title: String, icon: String, tab: MainTab) -> some View {
        Label(title, systemImage: store.selectedTab == tab ? "\(icon).fill" : icon)
            // 탭바가 아이콘을 자동으로 채우지 않게 해요
            .environment(\.symbolVariants, .none)
    }

    private func myView(store: StoreOf<MyFeature>) -> some View {
        @Bindable var store = store

        return MyView(store: store)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
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
    }
    
    private var recordMenu: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    store.send(.recordMenuDismissed)
                }
                .transition(.opacity)
            
            RecordMenuView { recordType in
                store.send(.recordTypeSelected(recordType))
            }
            .padding(.trailing, 16)
            .padding(.bottom, 64)
            .transition(.scale(scale: 0.8, anchor: .bottomTrailing).combined(with: .opacity))
        }
    }
}
