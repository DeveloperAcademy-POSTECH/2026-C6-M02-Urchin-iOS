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
        VStack(alignment: .leading, spacing: 0) {
            searchField
            favoriteSection

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if InputText.isBlank(store.query) {
                        if !store.recentSearches.isEmpty {
                            recentSection
                        }
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, 20.scaled)
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
        SearchBar {
            backButton
        } content: {
            searchTextField
        }
        .padding(.horizontal, 20.scaled)
        .padding(.vertical, 8.scaled)
        .padding(.bottom, 8.scaled)
    }
    
    var backButton: some View {
        Button {
            store.send(.backTapped)
        } label: {
            Image(.chevronLeft)
                .resizable()
                .frame(width: 24.scaled, height: 24.scaled)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로")
    }
    
    var searchTextField: some View {
        TextField(
            "",
            text: $store.query,
            prompt: Text(SearchBarPlaceholder.beachOrResort)
                .foregroundStyle(Color(.textSecondary))
        )
        .focused($isSearchFocused)
        .plobbyFont(.body)
        .foregroundStyle(Color(.textPrimary))
        .submitLabel(.search)
    }
}

// MARK: - 관심 해변

private extension SearchBeachView {

    var favoriteSection: some View {
        section("관심 해변") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8.scaled) {
                    ForEach(store.favoriteBeaches) { beach in
                        Button {
                            store.send(.resultTapped(beach.id))
                        } label: {
                            BeachChip(title: beach.name)
                        }
                        .buttonStyle(.plain)
                    }

                    if store.favoriteBeaches.count < Beach.maximumFavoriteCount {
                        Button {
                            // TODO: 관심 해변 추가 흐름 연결
                        } label: {
                            BeachChip(title: "추가", style: .add)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - 최근 검색

private extension SearchBeachView {

    var recentSection: some View {
        section("최근 검색") {
            VStack(spacing: 4.scaled) {
                ForEach(store.recentSearches) { beach in
                    HStack(spacing: 8.scaled) {
                        favoriteIcon(beach)

                        Button {
                            store.send(.recentTapped(beach))
                        } label: {
                            Text(beach.name)
                                .plobbyFont(.body)
                                .foregroundStyle(Color(.gray900))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.send(.recentDeleteTapped(beach), animation: .default)
                        } label: {
                            Image(.mapXmark)
                                .resizable()
                                .frame(width: 36.scaled, height: 36.scaled)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("최근 검색 삭제")
                    }
                    .padding(.vertical, 8.scaled)
                }
            }
        }
    }

    func favoriteIcon(_ beach: Beach) -> some View {
        let isFavorite = store.isMember && store.favoriteBeaches.contains { $0.id == beach.id }

        return Button {
            store.send(.favoriteTapped(beach))
        } label: {
            Group {
                if isFavorite {
                    Image(.starGreen)
                        .resizable()
                        .frame(width: 32.scaled, height: 32.scaled)
                } else {
                    Image(.mapPin)
                        .resizable()
                        .frame(width: 36.scaled, height: 36.scaled)
                }
            }
            .frame(width: 36.scaled, height: 36.scaled)
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
                        VStack(alignment: .leading, spacing: 4.scaled) {
                            Text(result.name)
                                .plobbyFont(.body)
                                .foregroundStyle(Color(.textPrimary))

                            Text(result.address)
                                .plobbyFont(.helper)
                                .foregroundStyle(Color(.textSecondary))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12.scaled)
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
            VStack(spacing: 4.scaled) {
                Text("검색 결과가 없어요")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textPrimary))

                Text("해변이나 해수욕장 이름으로 다시 검색해주세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80.scaled)
        }
    }
}

private extension SearchBeachView {
    
    func section(
        _ title: String
        , @ViewBuilder content: () -> some View)
    -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.gray900))
                .padding(.bottom, 16.scaled)

            content()
        }
        .padding(.vertical, 16.scaled)
    }
}
