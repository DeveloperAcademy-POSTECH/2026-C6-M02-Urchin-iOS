//
//  CompleteView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct CompleteView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<CompleteFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Text("회원가입이 완료되었습니다.")
                .font(.system(size: 26, weight: .semibold))
                .padding(.top, 85)
            
            Spacer()

            NormalButton(text: "완료") {
                store.send(.completeButtonTapped)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden()
    }
}
