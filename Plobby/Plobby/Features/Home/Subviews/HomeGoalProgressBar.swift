//
//  HomeGoalProgressBar.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeGoalProgressBar: View {

    let progress: Double
    var trackColor = Color(.gray200)

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(trackColor)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color(.currentBrandText))
                        .frame(width: proxy.size.width * progress)
                }
        }
        .frame(height: 8.scaled)
    }
}
