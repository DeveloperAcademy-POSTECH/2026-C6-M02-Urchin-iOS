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
            Text("관심 해변 선택 화면이지롱")

            Button("다음") {
                store.send(.nextButtonTapped)
            }
        }
    }
}
