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
            case let .collecting(store):
                RecordCollectingView(store: store)
            case let .reward(store):
                RecordRewardView(store: store)
            case let .detail(store):
                RecordDetailView(store: store)
            }
        }
    }
}
