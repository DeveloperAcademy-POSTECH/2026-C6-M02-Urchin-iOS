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
            collectionCard
            
            Spacer()
            
            bottomButtons
            
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
        Button {
            store.send(.profileTapped)
        } label: {
            profileThumbnail
        }
        .buttonStyle(.plain)
    }

    var profileThumbnail: some View {
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

// MARK: - Collection Card

private extension CollectionView {
    
    private var collectionCard: some View {
        CollectionCardView(store: store.scope(state: \.card, action: \.card))
            .padding(.horizontal, 32.scaled)
            .padding(.vertical, 24.scaled)
    }
}

// MARK: - Bottom

private extension CollectionView {

    var bottomButtons: some View {
        HStack(spacing: 8.scaled) {
            allCategoryButton
            shareButton
        }
        .padding(.horizontal, 32.scaled)
        .padding(.bottom, 28.scaled)
    }

    var allCategoryButton: some View {
        Button {
            store.send(.allCategoryTapped)
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 16.scaled, weight: .regular))
                    .frame(width: 24.scaled, height: 24.scaled)

                Text("전체 분류")
                    .plobbyFont(.actionLabel)
            }
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56.scaled)
            .background(Color(.gray100), in: RoundedRectangle(cornerRadius: 10.scaled))
        }
        .buttonStyle(.plain)
    }

    var shareButton: some View {
        Button {
            store.send(.shareTapped)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18.scaled, weight: .medium))
                .frame(width: 24.scaled, height: 24.scaled)
                .foregroundStyle(.textPrimary)
                .frame(width: 56.scaled, height: 56.scaled)
                .background(Color(.gray100), in: RoundedRectangle(cornerRadius: 10.scaled))
        }
        .buttonStyle(.plain)
    }
}
