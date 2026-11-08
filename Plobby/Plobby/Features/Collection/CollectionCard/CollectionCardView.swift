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
        FlipCard(
            angle: store.isFlipped ? 180 : 0,
            front: front,
            back: back
        )
        .animation(.easeInOut(duration: 0.6), value: store.isFlipped)
    }
}

// MARK: - 카드 앞면

private extension CollectionCardView {

    var front: some View {
        VStack(spacing: 0) {
            header
            trashPile
            collectedCount
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.darkBG), in: RoundedRectangle(cornerRadius: 20.scaled))
    }

    var header: some View {
        HStack(spacing: 0) {
            Text("플라스틱")    // TODO: - 수정 예정
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.gray0))
                .padding(.leading, 8.scaled)

            Spacer()

            flipButton
        }
        .padding(.top, 16.scaled)
        .padding(.horizontal, 16.scaled)
    }

    var flipButton: some View {
        Button {
            store.send(.flipButtonTapped)
        } label: {
            Image(.collectionCardFlip)
                .resizable()
                .frame(width: 23.scaled, height: 23.scaled)
                .frame(width: 42.scaled, height: 42.scaled)
                .foregroundStyle(Color(.gray0))
                .background(Color(.gray900), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.currentNeutralGray), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    var trashPile: some View {
        TrashPileView(
            category: store.selectedCategory,
            count: store.collectedCount
        )
        .id(store.selectedCategory)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16.scaled)
        .padding(.bottom, 8.scaled)
    }

    var collectedCount: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("지금까지 모은 개수")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.gray500))

            Spacer()

            Text("\(store.collectedCount)개")
                .plobbyFont(.metricExtra)
                .foregroundStyle(Color(.gray0))
        }
        .padding(.horizontal, 16.scaled)
        .padding(.bottom, 20.scaled)
    }
}

// MARK: - 카드 뒷면

private extension CollectionCardView {
    
    var back: some View {
        let fact = store.selectedCategory.collectionFact(count: store.collectedCount, nickname: store.nickname)

        return VStack(spacing: 0) {
            header
            helpText(fact.title)
            illustration
            description(fact.description)

            Spacer()

            source(fact.source)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.darkBG), in: RoundedRectangle(cornerRadius: 20.scaled))
    }

    func helpText(_ title: String) -> some View {
        var text = AttributedString(title)
        
        if let range = title.range(of: #"\d+(마리|L)"#, options: .regularExpression),
           let highlight = Range(range, in: text) {
            text[highlight].foregroundColor = Color(.darkBGGreen)
        }

        return Text(text)
            .plobbyFont(.metric)
            .foregroundStyle(Color(.gray0))
            .padding(.top, 25.scaled)
            .padding(.horizontal, 20.scaled)
    }

    // TODO: 종류별 일러스트 에셋 나오면 교체
    var illustration: some View {
        Color.red
            .frame(width: 167.scaled, height: 141.scaled)
            .padding(.top, 30.scaled)
    }

    func description(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.body)
            .foregroundStyle(Color(.gray0))
            .padding(.top, 22.scaled)
            .padding(.horizontal, 16.scaled)
    }

    func source(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.metadata)
            .foregroundStyle(Color(.gray0).opacity(0.72))
            .padding(.bottom, 36.scaled)
            .padding(.horizontal, 16.scaled)
    }
}
