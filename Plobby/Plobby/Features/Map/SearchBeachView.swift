//
//  SearchBeachView.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct SearchBeachView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<SearchBeachFeature>

    @FocusState private var isSearchFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            searchField
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if InputText.isBlank(store.query) {
                        if store.isMember, !store.favoriteBeaches.isEmpty {
                            favoriteSection
                        }

                        if !store.recentSearches.isEmpty {
                            recentSection
                        }
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
        .onAppear {
            isSearchFocused = true
        }
        .plobbyAlert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - 검색창

private extension SearchBeachView {

    var searchField: some View {
        HStack(spacing: 8) {
            Button {
                store.send(.backTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로")

            TextField(
                "",
                text: $store.query,
                prompt: Text("해변, 해수욕장 이름을 검색해주세요.")
                    .foregroundStyle(Color(.textTertiary))
            )
            .focused($isSearchFocused)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
            .submitLabel(.search)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.currentWarmBorder), lineWidth: 1)
        }
    }
}

// MARK: - 관심 해변

private extension SearchBeachView {

    // TODO: 관심 해변 추가 흐름이 정해지면 "+ 추가" 버튼 연결
    var favoriteSection: some View {
        section("관심 해변") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.favoriteBeaches) { beach in
                        Button {
                            store.send(.resultTapped(beach.id))
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color(.green500))
                                    .frame(width: 24, height: 24)

                                Text(beach.name)
                                    .font(.custom(PretendardWeight.semiBold.rawValue, size: 14))
                                    .foregroundStyle(Color(.textPrimary))
                            }
                            .padding(.leading, 8)
                            .padding(.trailing, 16)
                            .frame(height: 44)
                            .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.currentWarmBorder), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }
}

// MARK: - 최근 검색

private extension SearchBeachView {

    var recentSection: some View {
        section("최근 검색") {
            VStack(spacing: 4) {
                ForEach(store.recentSearches) { beach in
                    HStack(spacing: 8) {
                        favoriteIcon(beach)

                        Button {
                            store.send(.recentTapped(beach))
                        } label: {
                            Text(beach.name)
                                .plobbyFont(.body)
                                .foregroundStyle(Color(.textPrimary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.send(.recentDeleteTapped(beach), animation: .default)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(.textTertiary))
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(beach.name) 최근 검색 삭제")
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    /// 관심 해변이면 별, 아니면 핀. 로그인했으면 눌러서 관심 해변을 바꿀 수 있어요.
    func favoriteIcon(_ beach: Beach) -> some View {
        let isFavorite = store.isMember && store.favoriteBeaches.contains { $0.id == beach.id }

        return Button {
            store.send(.favoriteTapped(beach))
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "mappin.circle.fill")
                .font(.system(size: isFavorite ? 16 : 20))
                .foregroundStyle(isFavorite ? Color(.green500) : Color(.textTertiary))
                .frame(width: 36, height: 36)
                .background(Color(.gray50), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!store.isMember)
        .accessibilityLabel(isFavorite ? "관심 해변 해제" : "관심 해변 등록")
    }
}

// MARK: - 검색 결과

private extension SearchBeachView {

    @ViewBuilder
    var searchResults: some View {
        switch store.status {
        case .idle, .searching:
            EmptyView()

        case let .results(results):
            LazyVStack(spacing: 0) {
                ForEach(results) { result in
                    Button {
                        store.send(.resultTapped(result.id))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.name)
                                .plobbyFont(.body)
                                .foregroundStyle(Color(.textPrimary))

                            Text(result.address)
                                .plobbyFont(.helper)
                                .foregroundStyle(Color(.textSecondary))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color(.gray200))
                            .frame(height: 1)
                    }
                }
            }

        case .empty:
            VStack(spacing: 4) {
                Text("검색 결과가 없어요")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textPrimary))

                Text("해변이나 해수욕장 이름으로 다시 검색해주세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        }
    }

    func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            content()
        }
        .padding(.vertical, 16)
    }
}
