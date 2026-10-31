//
//  NormalButton.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

// TODO: 추후 디자인 시스템애 맞게 수정해주세요.
struct NormalButton: View {
    
    // MARK: - Properties
    
    @Environment(\.isEnabled) private var isEnabled
    
    let text: String
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    isEnabled
                    ? Color.white
                    : Color.gray.opacity(0.5)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 51)
                .background(
                    isEnabled
                    ? Color.black
                    : Color.gray.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 4)
                )
        }
    }
}
