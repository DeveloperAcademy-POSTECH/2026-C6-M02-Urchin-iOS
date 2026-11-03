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
            Tab("홈", systemImage: "house", value: .home) {
                HomeView(store: store.scope(state: \.home, action: \.home))
            }
            
            Tab("지도", systemImage: "map", value: .map) {
                Text("지도")
            }
            
            Tab("마이", systemImage: "person", value: .my) {
                Text("마이")
            }
            
            Tab("기록", systemImage: "plus", value: .record, role: .search) {
                EmptyView()
            }
        }
        .tint(.primary)
        .sheet(isPresented: $store.isRecordSheetPresented.sending(\.recordSheetPresentedChanged)) {
            Text("기록 작성")
        }
    }
}
