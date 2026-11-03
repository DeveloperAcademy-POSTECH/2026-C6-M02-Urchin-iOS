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
            searchField

            HStack(spacing: 0) {
                seaList
                beachList
            }
        }
        .frame(height: 432)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Subviews

extension RegionPicker {

    private var searchField: some View {
        TextField(
            "지역 이름 검색",
            text: $store.searchText.sending(\.searchTextChanged)
        )
        .font(.system(size: 16, weight: .regular))
        .padding(.horizontal, 20)
        .frame(height: 48)
        .background(Color.gray.opacity(0.08))
    }

    private var seaList: some View {
        VStack(spacing: 0) {
            ForEach(Sea.allCases, id: \.self) { sea in
                seaButton(sea)
            }
        }
        .frame(width: 98)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.gray.opacity(0.08))
    }

    private func seaButton(_ sea: Sea) -> some View {
        let isSelected = store.selectedSea == sea

        return Button {
            store.send(.seaTapped(sea))
        } label: {
            Text(sea.title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.black : Color.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isSelected ? Color.gray.opacity(0.15) : Color.clear)
        }
    }

    private var beachList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.beaches) { beach in
                beachButton(beach)
            }
        }
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func beachButton(_ beach: Beach) -> some View {
        let isSelected = store.selectedBeachIDs.contains(beach.id)

        return Button {
            store.send(.beachTapped(beach.id))
        } label: {
            HStack(spacing: 8) {
                Text(beach.name)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(.black)
            .frame(height: 54)
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
