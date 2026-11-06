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
        // 지도 탭이 자기 내비게이션 스택을 가지도록 탭마다 스택을 따로 둬요. 쌓인 화면에서는 탭 바를 숨겨요.
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            Tab("홈", systemImage: "house", value: .home) {
                NavigationStack {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(
                            item: $store.scope(state: \.home.favoriteBeachPicker, action: \.home.favoriteBeachPicker)
                        ) { store in
                            FavoriteBeachView(store: store)
                                .toolbar(.hidden, for: .tabBar)
                        }
                        .navigationDestination(
                            item: $store.scope(state: \.home.notification, action: \.home.notification)
                        ) { store in
                            NotificationView(store: store)
                                .toolbar(.hidden, for: .tabBar)
                        }
                }
            }

            Tab("지도", systemImage: "map", value: .map) {
                MapView(store: store.scope(state: \.map, action: \.map))
            }

            Tab("마이", systemImage: "person", value: .my) {
                NavigationStack {
                    MyView(store: store.scope(state: \.my, action: \.my))
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(
                            item: $store.scope(state: \.my.profileEdit, action: \.my.profileEdit)
                        ) { store in
                            ProfileEditView(store: store)
                                .toolbar(.hidden, for: .tabBar)
                        }
                        .navigationDestination(
                            item: $store.scope(state: \.my.settings, action: \.my.settings)
                        ) { store in
                            SettingsView(store: store)
                                .toolbar(.hidden, for: .tabBar)
                        }
                }
            }

            Tab("기록", systemImage: store.isRecordMenuPresented ? "xmark" : "plus", value: .record, role: .search) {
                EmptyView()
            }
        }
        .tint(.primary)
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
        .overlay(alignment: .bottomTrailing) {
            if store.isRecordMenuPresented {
                recordMenu
            }
        }
        .animation(.spring(duration: 0.25), value: store.isRecordMenuPresented)
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
        .plobbyAlert($store.scope(state: \.signIn.alert, action: \.signIn.alert))
    }
}

// MARK: - Subviews

extension MainTabView {
    
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
