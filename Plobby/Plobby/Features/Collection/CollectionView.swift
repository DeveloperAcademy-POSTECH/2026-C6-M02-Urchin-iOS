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
    @State private var cardsFrame: CGRect = .zero
    @State private var scrolledCategory: TrashCategory?

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
        .onChange(of: store.shareRequestCount) {
            shareCurrentCard()
        }
        .sheet(isPresented: $store.isCategorySheetPresented.sending(\.categorySheetPresentationChanged)) {
            CollectionCategorySheet(store: store)
                .presentationDetents([.height(684.scaled)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: activityPickerBinding) {
            HomeActivityPicker(
                onSelect: { type in store.send(.activityPicked(type), transaction: Self.noAnimation) },
                onDismiss: { store.send(.activityPickerDismissed, transaction: Self.noAnimation) }
            )
            .presentationBackground(.clear)
        }
    }
}

// MARK: - Activity Picker

private extension CollectionView {

    var activityPickerBinding: Binding<Bool> {
        Binding(
            get: { store.isActivityPickerPresented },
            set: { if !$0 { store.send(.activityPickerDismissed, transaction: Self.noAnimation) } }
        )
    }

    static var noAnimation: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
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
        CollectionProfileImage(url: store.profile?.profileImageURL)
            .frame(width: 36.scaled, height: 36.scaled)
            .clipShape(Circle())
            .unreadDot(store.hasUnreadNotification, inset: Self.unreadDotInset)
    }
}

private extension CollectionView {

    /// 빨간 점 중심이 프로필 원의 오른쪽 위 곡선(45도) 위에 오도록 안쪽으로 옮기는 값이에요.
    static let unreadDotInset: CGSize = {
        let profileRadius = 18.scaled
        let dotRadius = 4.scaled
        let inset = profileRadius * (1 - cos(.pi / 4)) - dotRadius
        return CGSize(width: inset, height: inset)
    }()
}

private struct CollectionProfileImage: View {

    let url: URL?

    @State private var image: UIImage?
    @State private var loadedURL: URL?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(Color(.gray600))
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                loadedURL = nil
                return
            }
            guard url != loadedURL else { return }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let loaded = UIImage(data: data) else { return }

                image = loaded
                loadedURL = url
            } catch {
                if !(error is CancellationError), (error as? URLError)?.code != .cancelled {
                    PlobbyLogger.error(error)
                }
            }
        }
    }
}

// MARK: - Collection Cards

private extension CollectionView {

    nonisolated static let peekScale: CGFloat = 277 / 338

    var collectionCards: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 7.scaled) {
                ForEach(store.scope(state: \.cards, action: \.cards), id: \.state.id) { cardStore in
                    CollectionCardView(
                        store: cardStore,
                        isActive: store.isTrashCountsLoaded && cardStore.category == scrolledCategory,
                        isGuest: store.membershipStatus == .guest
                    )
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
        .scrollPosition(id: $scrolledCategory)
        .onAppear {
            scrolledCategory = store.selectedCategory
        }
        .onChange(of: scrolledCategory) { _, category in
            guard let category, category != store.selectedCategory else { return }

            store.send(.cardScrolled(category))
        }
        .onChange(of: store.selectedCategory) { _, category in
            guard category != scrolledCategory else { return }

            withAnimation {
                scrolledCategory = category
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            cardsFrame = frame
        }
        .padding(.vertical, 24.scaled)
    }
}

// MARK: - Bottom

private extension CollectionView {

    var bottomButtons: some View {
        HStack(spacing: 8.scaled) {
            allCategoryButton

            if store.membershipStatus != .guest {
                shareButton
            }
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
            store.send(.shareButtonTapped)
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

    func shareCurrentCard() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first
        else { return }

        let cardFrame = cardsFrame.insetBy(dx: 32.scaled, dy: 0)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false

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
