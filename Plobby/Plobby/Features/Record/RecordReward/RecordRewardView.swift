//
//  RecordRewardView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordRewardView: View {
    
    let store: StoreOf<RecordRewardFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Record Reward")
            
            Button("다음") {
                store.send(.nextButtonTapped)
            }
            
            Button("닫기") {
                store.send(.closeButtonTapped)
            }
        }
    }
}
