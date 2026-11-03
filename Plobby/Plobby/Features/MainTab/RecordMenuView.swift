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

    private let recordTypes: [RecordType] = [.plogging, .plobbing]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("기록하기")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            ForEach(recordTypes, id: \.self) { recordType in
                Button {
                    onSelect(recordType)
                } label: {
                    Text(title(for: recordType))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 232)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        }
    }

    // MARK: - Functions

    private func title(for recordType: RecordType) -> String {
        switch recordType {
        case .plogging:
            return "플로깅"
        case .plobbing:
            return "플로빙"
        }
    }
}
