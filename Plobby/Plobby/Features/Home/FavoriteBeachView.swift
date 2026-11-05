//
//  FavoriteBeachView.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

import ComposableArchitecture

struct FavoriteBeachView: View {

    // MARK: - Properties

    let store: StoreOf<RegionFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            title
            RegionPicker(store: store)

            Spacer()

            saveButton
        }
    }
}

// MARK: - Subviews

extension FavoriteBeachView {

    private var title: some View {
        Text("관심 해변을\n선택해주세요")
            .font(.system(size: 26, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 21)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
    }

    private var saveButton: some View {
        NormalButton(text: "저장") {
            store.send(.nextButtonTapped)
        }
        .padding(.horizontal, 20)
    }
}
