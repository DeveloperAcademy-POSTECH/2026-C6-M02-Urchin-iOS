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
        NavigationStack {
            TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
                Tab("홈", systemImage: "house", value: .home) {
                    HomeView(store: store.scope(state: \.home, action: \.home))
                }

                Tab("지도", systemImage: "map", value: .map) {
                    Text("지도")
                }

                Tab("마이", systemImage: "person", value: .my) {
                    MyView(store: store.scope(state: \.my, action: \.my))
                }

                Tab("기록", systemImage: store.isRecordMenuPresented ? "xmark" : "plus", value: .record, role: .search) {
                    EmptyView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                item: $store.scope(state: \.home.favoriteBeachPicker, action: \.home.favoriteBeachPicker)
            ) { store in
                FavoriteBeachView(store: store)
            }
            .navigationDestination(
                item: $store.scope(state: \.my.profileEdit, action: \.my.profileEdit)
            ) { store in
                ProfileEditView(store: store)
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
