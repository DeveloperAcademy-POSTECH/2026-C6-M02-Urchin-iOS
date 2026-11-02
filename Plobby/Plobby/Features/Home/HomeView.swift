//
//  HomeView.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import SwiftUI

import ComposableArchitecture

struct HomeView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<HomeFeature>
    
    // MARK: - Body
    
    var body: some View {
        switch store.status {
        case .member:
            Text("회원 홈화면이지롱")
            
        case .guest:
            Text("비회원 홈화면이지롱")
        }
    }
}
