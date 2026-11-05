//
//  RecordMenuView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct RecordMenuView: View {
    
    // MARK: - Properties
    
    let onSelect: (RecordType) -> Void
        
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(RecordType.allCases, id: \.self) { recordType in
                Button {
                    onSelect(recordType)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Image(recordType.image)
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text(recordType.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(height: 48)
                            .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 14)
        .frame(width: 180)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }
}
