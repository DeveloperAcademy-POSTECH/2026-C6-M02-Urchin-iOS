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
                RecordFormView(store: store)
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .opacity.animation(.linear(duration: 0.01).delay(RecordRewardView.curtainDuration))
                    ))
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
