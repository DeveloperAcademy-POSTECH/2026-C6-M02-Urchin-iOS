//
//  RecordView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<RecordFlowFeature>
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            switch store.scope(state: \.step, action: \.step).case {
            case let .photoPicker(store):
                PhotosPickerView(store: store)
            case let .form(store):
                // 리워드 화면이 덮을 때까지 그대로 남아 있어요
                RecordFormView(store: store)
                    .transition(.identity)
            case let .reward(store):
                RecordRewardView(store: store)
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .identity))
                    .zIndex(1)
            case let .detail(store):
                RecordDetailView(store: store)
            }
        }
        .animation(.easeInOut(duration: RecordRewardView.curtainDuration), value: store.step.is(\.reward))
    }
}
