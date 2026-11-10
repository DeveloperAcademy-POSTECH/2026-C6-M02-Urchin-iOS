//
//  RecordCollectingView.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordCollectingView: View {

    // MARK: - Properties

    let store: StoreOf<RecordCollectingFeature>

    // MARK: - Body

    var body: some View {
        Text("쓰레기를 쏙쏙 담아 모으고 있어요")
            .plobbyFont(.body2)
            .foregroundStyle(Color(.textPrimary))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.backgroundDefault))
            .onAppear {
                store.send(.onAppear)
            }
    }
}

// MARK: - Preview

#Preview {
    RecordCollectingView(
        store: Store(
            initialState: RecordCollectingFeature.State(recordID: UUID(), beachName: nil, trash: TrashSelection(), weightKg: nil)
        ) {
            RecordCollectingFeature()
        }
    )
}
