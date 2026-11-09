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

            HStack(spacing: 0) {
                regionList
                beachList
            }
        }
    }
}

// MARK: - Subviews

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

private extension RegionPicker {

    private var regionList: some View {
        VStack(spacing: 0) {
            regionButton(nil)

            ForEach(Sea.allCases, id: \.self) { region in
                regionButton(region)
            }
        }
        .frame(width: 98)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.gray.opacity(0.08))
    }

    private func regionButton(_ region: Sea?) -> some View {
        let isSelected = store.selectedRegion == region

        return Button {
            store.send(.regionTapped(region))
        } label: {
            Text(region?.title ?? "전체")
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.black : Color.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isSelected ? Color.gray.opacity(0.15) : Color.clear)
        }
    }

    private var beachList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.beaches) { beach in
                    beachButton(beach)
                }
            }
            .padding(.horizontal, 22)
        }
        .scrollIndicators(.hidden)
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

// MARK: - Preview

#Preview {
    let beaches = [
        Beach(id: UUID(), region: .east, name: "영일대 해수욕장", address: "경북 포항시", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .east, name: "경포 해수욕장", address: "강원 강릉시", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .east, name: "속초 해수욕장", address: "강원 속초시", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .south, name: "해운대 해수욕장", address: "부산 해운대구", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .south, name: "광안리 해수욕장", address: "부산 수영구", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .west, name: "대천 해수욕장", address: "충남 보령시", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .west, name: "을왕리 해수욕장", address: "인천 중구", latitude: 0, longitude: 0),
        Beach(id: UUID(), region: .jeju, name: "협재 해수욕장", address: "제주 제주시", latitude: 0, longitude: 0)
    ]

    // 미리보기용 해변 목록을 넣어요 (미리보기에서는 파일이 아니라 메모리에 저장돼요)
    let _ = {
        @Shared(.beaches) var allBeaches
        $allBeaches.withLock { $0 = beaches }
    }()

    // 첫 해변은 선택된 상태로 보여줘요
    let state = {
        var state = RegionFeature.State()
        state.selectedBeachIDs = [beaches[0].id]
        return state
    }()

    RegionPicker(
        store: Store(initialState: state) {
            RegionFeature()
        }
    )
    .padding(.horizontal, 20)
}
