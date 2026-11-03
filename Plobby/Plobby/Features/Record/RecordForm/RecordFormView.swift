//
//  RecordFormView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordFormView: View {
    
    let store: StoreOf<RecordFormFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Record Form")
            
            Button("저장") {
                store.send(.saveButtonTapped)
            }
            
            Button("닫기") {
                store.send(.closeButtonTapped)
            }
        }
    }
}
