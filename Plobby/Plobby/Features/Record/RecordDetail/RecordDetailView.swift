//
//  RecordDetailView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordDetailView: View {
    
    let store: StoreOf<RecordDetailFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Record Detail")
            
            Button("닫기") {
                store.send(.closeButtonTapped)
            }
        }
    }
}
