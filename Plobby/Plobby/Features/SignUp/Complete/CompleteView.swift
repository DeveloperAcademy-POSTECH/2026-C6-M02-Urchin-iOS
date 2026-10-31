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
        Text("회원가입 완료 화면이지롱")
        
        Button("완료") {
            print("완료~~")
        }
    }
}
