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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.neutralBlack), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

// MARK: - Subviews

private extension CollectionCardView {

    var header: some View {
        HStack {
            Menu {
                ForEach(TrashCategory.allCases, id: \.self) { category in
                    Button(category.name) {
                        store.send(.categorySelected(category))
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Text(store.selectedCategory.name)
                        .plobbyFont(.metric)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(Color(.gray0))
                .fixedSize()
            }
            // 메뉴가 닫히는 애니메이션 중 제목이 바뀌면 이전 폭으로 잘린 채 남는 iOS 26 문제를 피하려고, 선택이 바뀔 때마다 라벨을 새로 만들어요
            .id(store.selectedCategory)

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
        .padding(.top, 16)
        .padding(.horizontal, 20)
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
                .plobbyFont(.helper)
                // TODO: 컬러셋 확정 후 교체
                .foregroundStyle(Color(red: 0xB7 / 255, green: 0xC3 / 255, blue: 0xBC / 255))

            Spacer()

            Text("\(store.collectedCount)개")
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 44))
                .foregroundStyle(Color(.gray0))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 48)
    }
}

#Preview {
    CollectionCardView(
        store: Store(initialState: CollectionCardFeature.State()) {
            CollectionCardFeature()
        }
    )
}
