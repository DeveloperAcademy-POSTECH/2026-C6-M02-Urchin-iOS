//
//  RegionView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct RegionView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<RegionFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            title
            subTitle
            
            regionPicker
            
            Spacer()
            
            nextButton
        }
    }
}

// MARK: - Subviews

extension RegionView {
    
    private var title: some View {
        Text("즐겨찾기에 넣을 해변을\n선택해주세요")
            .font(.system(size: 26, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 21)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
    }
    
    private var subTitle: some View {
        Text("즐겨찾기에 넣을 해변은 마이페이지에서\n언제든 다시 바꿀 수 있어요")
            .font(.system(size: 14, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 53)
    }
    
    private var regionPicker: some View {
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
    
    private var nextButton: some View {
        NormalButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .padding(.horizontal, 20)
    }
}
