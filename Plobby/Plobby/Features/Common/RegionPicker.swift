//
//  RegionPicker.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

import ComposableArchitecture

struct RegionPicker: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<RegionFeature>

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            regionSection
        }
    }
}

// MARK: - 검색창

private extension RegionPicker {
    
    var searchBar: some View {
        SearchBar {
            Image(systemName: "magnifyingglass")
        } content: {
            TextField(
                "",
                text: $store.searchText.sending(\.searchTextChanged),
                prompt: Text(SearchBarPlaceholder.beachName)
                    .foregroundStyle(Color(.textSecondary))
            )
            .foregroundStyle(Color(.textPrimary))
        }
        .padding(.bottom, 16)
    }
}

// MARK: - 지역·해변 영역

private extension RegionPicker {

    var regionSection: some View {
        HStack(spacing: 0) {
            regionList
            divider
            beachList
        }
    }

    var divider: some View {
        Rectangle()
            .fill(Color(.borderSubtle))
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .padding(.leading, 8.scaled)
            .padding(.trailing, 7.scaled)
    }
}

// MARK: - 지역 목록

private extension RegionPicker {

    var regionList: some View {
        VStack(spacing: 8.scaled) {
            regionButton(nil)

            ForEach(Sea.allCases, id: \.self) { region in
                regionButton(region)
            }
        }
        .frame(width: 88.scaled)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    func regionButton(_ region: Sea?) -> some View {
        let isSelected = store.selectedRegion == region

        return Button {
            store.send(.regionTapped(region))
        } label: {
            Text(region?.title ?? "전국")
                .plobbyFont(.actionLabel)
                .foregroundStyle(isSelected ? Color(.gray0) : Color(.textSecondary))
                .padding(.leading, 12.scaled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 48.scaled)
                .background(
                    isSelected ? Color(.green500) : .clear,
                    in: RoundedRectangle(cornerRadius: 12.scaled)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 해변 목록

private extension RegionPicker {

    var beachList: some View {
        ScrollView {
            LazyVStack(spacing: 8.scaled) {
                ForEach(store.beaches) { beach in
                    beachButton(beach)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.leading, 7.scaled)
    }

    func beachButton(_ beach: Beach) -> some View {
        let isSelected = store.selectedBeachIDs.contains(beach.id)

        return Button {
            store.send(.beachTapped(beach.id))
        } label: {
            Text(beach.name)
                .plobbyFont(isSelected ? .actionLabel : .body)
                .foregroundStyle(isSelected ? Color(.currentBrandText) : Color(.textPrimary))
                .padding(.horizontal, 12.scaled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 48.scaled)
                .background(
                    isSelected ? Color(.brandPrimarySubtle) : .clear,
                    in: RoundedRectangle(cornerRadius: 12.scaled)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
