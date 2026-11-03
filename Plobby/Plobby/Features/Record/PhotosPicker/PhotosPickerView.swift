//
//  PhotosPickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

import ComposableArchitecture

struct PhotosPickerView: View {
    
    let store: StoreOf<PhotosPickerFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Photos Picker")
            
            Button("다음") {
                store.send(.nextButtonTapped)
            }
            
            Button("닫기") {
                store.send(.closeButtonTapped)
            }
        }
    }
}
