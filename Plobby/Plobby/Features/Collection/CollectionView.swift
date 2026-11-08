//
//  CollectionView.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

struct CollectionView: View {

    // MARK: - Properties

    let store: StoreOf<CollectionFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer()
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Header

private extension CollectionView {

    var header: some View {
        HStack {
            Text("컬렉션")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.gray900))

            Spacer()

            profileImage
        }
        .frame(height: 44.scaled)
        .padding(.horizontal, 20.scaled)
    }

    var profileImage: some View {
        AsyncImage(url: store.profile?.profileImageURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(Color(.gray600))
        }
        .frame(width: 36.scaled, height: 36.scaled)
        .clipShape(Circle())
    }
}
