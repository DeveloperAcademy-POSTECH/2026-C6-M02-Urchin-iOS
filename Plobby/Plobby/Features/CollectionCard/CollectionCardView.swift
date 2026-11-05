//
//  CollectionCardView.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct CollectionCardView: View {

    // MARK: - Properties

    let store: StoreOf<CollectionCardFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            
            Spacer()
            
            trashPile
            collectedCount
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.neutralBlack), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

// MARK: - Subviews

private extension CollectionCardView {

    var header: some View {
        HStack {
            Button {
                store.send(.categoryButtonTapped)
            } label: {
                HStack(spacing: 7) {
                    Text(store.selectedCategory.name)
                        .plobbyFont(.metric)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(Color(.gray0))
            }

            Spacer()

            Button {
                store.send(.flipButtonTapped)
            } label: {
                // TODO: 디자인 시스템 확정 후 변경
                Image(.collectionCardFlip)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .background(Color(.gray900), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(Color(.gray700), lineWidth: 1)
                    }
            }
        }
    }

    // TODO: 모은 쓰레기가 쌓이는 SpriteKit 장면으로 교체
    var trashPile: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 360)
    }

    var collectedCount: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("지금까지 모은 개수")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.gray0))
                .opacity(0.72)

            Spacer()

            Text("\(store.collectedCount)개")
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 48))
                .foregroundStyle(Color(.gray0))
        }
    }
}

#Preview {
    CollectionCardView(
        store: Store(initialState: CollectionCardFeature.State()) {
            CollectionCardFeature()
        }
    )
}
