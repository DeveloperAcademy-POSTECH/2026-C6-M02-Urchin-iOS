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
    
    let store: StoreOf<RegionFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            title
            subTitle
            RegionPicker(store: store)
            
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
    
    private var nextButton: some View {
        PlobbyButton(text: "다음") {
            store.send(.nextButtonTapped)
        }
        .padding(.horizontal, 20)
    }
}
