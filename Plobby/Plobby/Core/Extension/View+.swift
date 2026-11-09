//
//  View+.swift
//  Plobby
//
//  Created by 이은지 on 11/9/26.
//

import SwiftUI

extension View {
    
    func plobbyNavigationTitle(_ title: String) -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .plobbyFont(.cardTitle)
                        .foregroundStyle(Color(.textPrimary))
                }
            }
    }
}
