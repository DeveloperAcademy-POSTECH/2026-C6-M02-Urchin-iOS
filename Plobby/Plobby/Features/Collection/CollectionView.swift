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

    @Bindable var store: StoreOf<CollectionFeature>

    /// 공유할 때 가운데 카드 영역을 잘라내려고 카드 스크롤 영역의 화면 위치를 기억해요
    @State private var cardsFrame: CGRect = .zero

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            collectionCards
            
            Spacer()
            
            bottomButtons
            
            Spacer()
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(isPresented: $store.isCategorySheetPresented.sending(\.categorySheetPresentationChanged)) {
            CollectionCategorySheet(store: store)
                .presentationDetents([.height(684.scaled)])
                .presentationDragIndicator(.visible)
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

// MARK: - Collection Cards

private extension CollectionView {

    nonisolated static let peekScale: CGFloat = 277 / 338

    var collectionCards: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 7.scaled) {
                ForEach(store.scope(state: \.cards, action: \.cards)) { cardStore in
                    CollectionCardView(store: cardStore)
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content.scaleEffect(
                                1 - (1 - Self.peekScale) * abs(phase.value),
                                anchor: phase.value < 0 ? .trailing : .leading
                            )
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 32.scaled, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: selectedCategory)
        .scrollIndicators(.hidden)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            cardsFrame = frame
        }
        .padding(.vertical, 24.scaled)
    }

    var selectedCategory: Binding<TrashCategory?> {
        Binding(
            get: { store.selectedCategory },
            set: { category in
                guard let category, category != store.selectedCategory else { return }

                store.send(.cardScrolled(category))
            }
        )
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
            shareCurrentCard()
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

// MARK: - Share

private extension CollectionView {

    /// 화면에 보이는 가운데 카드를 이미지로 찍어서 공유 시트를 띄워요
    func shareCurrentCard() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first
        else { return }

        let cardFrame = cardsFrame.insetBy(dx: 32.scaled, dy: 0)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false

        // ImageRenderer는 SpriteView(쓰레기 더미)를 그리지 못해서 화면을 그대로 찍어요
        let image = UIGraphicsImageRenderer(bounds: cardFrame, format: format).image { _ in
            UIBezierPath(roundedRect: cardFrame, cornerRadius: 20.scaled).addClip()
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }

        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = window
        activityViewController.popoverPresentationController?.sourceRect = cardFrame

        var topViewController = window.rootViewController
        while let presented = topViewController?.presentedViewController {
            topViewController = presented
        }
        topViewController?.present(activityViewController, animated: true)
    }
}
