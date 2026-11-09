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
    var isActive = true

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

// MARK: - 카드 공통

private extension CollectionCardView {

    func cardFace(_ content: some View) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.surfaceBlack), in: RoundedRectangle(cornerRadius: 20.scaled))
    }

    var header: some View {
        HStack(spacing: 0) {
            Text(store.category.name)
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
}

// MARK: - 카드 앞면

private extension CollectionCardView {

    var front: some View {
        cardFace(
            VStack(spacing: 0) {
                header

                if store.collectedCount > 0 {
                    trashPile
                } else {
                    emptyState
                }

                collectedCountLabel
            }
        )
    }

    var emptyState: some View {
        VStack(spacing: 0) {
            Image(store.category.thumbnailName)
                .resizable()
                .scaledToFit()
                .frame(width: 80.scaled, height: 80.scaled)
                .padding(.bottom, 20.scaled)

            Text("아직 수거 기록이 없어요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.gray0))
                .padding(.bottom, 8.scaled)

            Text("\(store.category.name)\(store.category.name.objectParticle) 수거한 활동을 기록하면\n이 카드에 차곡차곡 쌓여요.")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textDisabled))
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16.scaled)
    }

    var trashPile: some View {
        TrashPileView(
            category: store.category,
            count: store.collectedCount,
            isActive: isActive
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16.scaled)
        .padding(.bottom, 8.scaled)
    }

    var collectedCountLabel: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("지금까지 모은 개수")
                .plobbyFont(.metadata)
                .foregroundStyle(Color(.textDisabled))

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
        let fact = store.category.collectionFact(count: store.collectedCount, nickname: store.nickname)

        return cardFace(
            VStack(spacing: 0) {
                header
                factTitle(fact.title)
                illustration
                
                Spacer()

                factDescription(fact.description)

                Spacer()

                factSource(fact.source)
            }
            .multilineTextAlignment(.center)
        )
    }

    func factTitle(_ title: String) -> some View {
        var text = AttributedString(title)
        
        if let range = title.range(of: #"\d+(마리|L)"#, options: .regularExpression),
           let highlight = Range(range, in: text) {
            text[highlight].foregroundColor = Color(.darkBGGreen)
        }

        return Text(text)
            .plobbyFont(.metric)
            .foregroundStyle(Color(.gray0))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 25.scaled)
            .padding(.horizontal, 20.scaled)
    }

    /// 종류별로 지켜낸 바다 생물 일러스트예요. 작은 화면에서 글이 넘치지 않게, 공간이 모자라면 일러스트가 먼저 줄어들어요
    var illustration: some View {
        Image(store.category.collectionIllustrationName)
            .resizable()
            .scaledToFit()
            .frame(width: 242.scaled)
            .frame(minHeight: 0, maxHeight: 176.scaled)
            .padding(.top, 30.scaled)
            .accessibilityHidden(true)
    }

    func factDescription(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.body)
            .foregroundStyle(Color(.gray0))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 22.scaled)
            .padding(.horizontal, 16.scaled)
    }

    func factSource(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.metadata)
            .foregroundStyle(Color(.gray0).opacity(0.72))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 36.scaled)
            .padding(.horizontal, 16.scaled)
    }
}
