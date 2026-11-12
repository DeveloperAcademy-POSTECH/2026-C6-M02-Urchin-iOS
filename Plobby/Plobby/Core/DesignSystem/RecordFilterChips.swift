//
//  RecordFilterChips.swift
//  Plobby
//
//  Created by 이은지 on 11/12/26.
//

import SwiftUI

struct RecordFilterChips: View {
    
    // MARK: - Properties

    let selectedFilter: RecordFilter
    let onFilterChanged: (RecordFilter) -> Void

    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .center, spacing: 8.scaled) {
            ForEach(RecordFilter.allCases, id: \.self) { filter in
                let isSelected = selectedFilter == filter

                Button {
                    onFilterChanged(filter)
                } label: {
                    Text(filter.title)
                        .plobbyFont(.labelSelected)
                        .foregroundStyle(isSelected ? Color(.gray0) : Color(.textPrimary))
                        .padding(.horizontal, 16.scaled)
                        .frame(height: 36.scaled)
                        .background(isSelected ? Color(.gray800) : Color(.gray50), in: Capsule())
                        .overlay {
                            if !isSelected {
                                Capsule()
                                    .stroke(Color(.currentWarmBorder), lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
