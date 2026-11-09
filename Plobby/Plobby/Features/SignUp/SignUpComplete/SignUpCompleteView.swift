//
//  SignUpCompleteView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct SignUpCompleteView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<SignUpCompleteFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
            
            Text("회원가입이 완료되었습니다\n활동을 기록해보세요")
                .plobbyFont(.heading)
                .multilineTextAlignment(.center)
            
            Spacer()

            PlobbyButton(text: "완료") {
                store.send(.completeButtonTapped)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden()
    }
}
