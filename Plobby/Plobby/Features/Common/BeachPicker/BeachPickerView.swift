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
        .scrollDismissesKeyboard(.immediately)
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

// MARK: - BeachPickerBottomBar

struct BeachPickerBottomBar: View {

    // MARK: - Properties

    let store: StoreOf<BeachPickerFeature>
    let emptyMessage: String
    let buttonTitle: String
    var isButtonDisabled = false
    let onButtonTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            selectionSection

            PlobbyButton(text: buttonTitle, action: onButtonTapped)
                .disabled(isButtonDisabled)
        }
        .padding(.top, 16.scaled)
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 14.scaled)
        .background(Color(.backgroundDefault))
    }
}

// MARK: - 고른 해변

private extension BeachPickerBottomBar {

    @ViewBuilder
    var selectionSection: some View {
        if store.selectedBeaches.isEmpty {
            Text(emptyMessage)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8.scaled)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if store.isSelectionFull {
                    Text("관심 해변은 \(Beach.maximumFavoriteCount)개까지만 고를 수 있어요")
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.textSecondary))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 4.scaled) {
                        ForEach(store.selectedBeaches) { beach in
                            selectedBeachChip(beach)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(height: 44.scaled)
            }
        }
    }

    func selectedBeachChip(_ beach: Beach) -> some View {
        Button {
            store.send(.beachTapped(beach.id))
        } label: {
            HStack(spacing: 0) {
                Text(beach.name)
                    .plobbyFont(.label)
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(.system(size: 12.scaled))
                    .frame(width: 28.scaled, height: 32.scaled)
            }
            .foregroundStyle(Color(.textBrand))
            .padding(.leading, 12.scaled)
            .frame(height: 32.scaled)
            .background(Color(.surfaceBrandSubtle), in: Capsule())
            .frame(height: 44.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(beach.name) 선택 해제")
    }
}
