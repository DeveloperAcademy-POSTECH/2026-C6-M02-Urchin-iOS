//
//  BeachPickerView.swift
//  Plobby
//
//  Created by 이은지 on 11/4/26.
//

import SwiftUI

import ComposableArchitecture

struct BeachPickerView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<BeachPickerFeature>
    /// 지역·해변 영역 높이예요. nil이면 남은 공간을 모두 채우고, 해변 목록은 그 안에서 스크롤돼요.
    var regionSectionHeight: CGFloat? = 272.scaled

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            regionSection
        }
    }
}

// MARK: - 검색창

private extension BeachPickerView {
    
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

private extension BeachPickerView {

    /// 기본 높이는 지역 5개(높이 48 × 5 + 간격 8 × 4)가 딱 들어가는 높이예요. 해변이 많으면 오른쪽 목록만 스크롤돼요
    var regionSection: some View {
        HStack(spacing: 0) {
            regionList
            divider
            beachList
        }
        .frame(height: regionSectionHeight)
        .frame(maxHeight: regionSectionHeight == nil ? .infinity : nil)
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

private extension BeachPickerView {

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

private extension BeachPickerView {

    var beachList: some View {
        ScrollView {
            LazyVStack(spacing: 8.scaled) {
                ForEach(store.beaches) { beach in
                    beachButton(beach)
                }
            }
        }
        // 검색창을 누른 채 검색하지 않고 목록을 스크롤하면 키보드를 내려요
        .scrollDismissesKeyboard(.immediately)
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
