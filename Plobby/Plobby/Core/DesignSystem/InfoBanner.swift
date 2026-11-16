//
//  InfoBanner.swift
//  Plobby
//
//  Created by 더스틴 on 11/16/26.
//

import SwiftUI

struct InfoBanner: View {
    
    let information: String
    
    var body: some View {
        HStack(spacing: 8.scaled) {
            Image(systemName: "info.circle")
                .font(.system(size: 16.scaled, weight: .medium))

            Text(information)
                .plobbyFont(.metadata)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(.textSecondary))
        .padding(12.scaled)
        .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 12.scaled))
    }
}
