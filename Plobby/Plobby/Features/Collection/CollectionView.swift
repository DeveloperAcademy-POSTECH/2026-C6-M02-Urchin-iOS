//
//  CollectionView.swift
//  Plobby
//
//  Created by 이은지 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

struct CollectionView: View {

    // MARK: - Properties

    let store: StoreOf<CollectionFeature>

    // MARK: - Body

    var body: some View {
        Text("컬렉션")
    }
}
