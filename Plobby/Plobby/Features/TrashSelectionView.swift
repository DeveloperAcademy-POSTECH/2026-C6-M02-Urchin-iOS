//
//  TrashSelectionView.swift
//  Plobby
//
//  Created by 이은지 on 11/2/26.
//

import SwiftUI

// TODO: - 쓰레기 개수를 애니메이션 View로 넘기기 위한 위한 임시 Stepper View

struct TrashSelectionView: View {
    
    // MARK: - Properties
    
    @State private var assetCounts: [String: Int] = [:]
    @State private var isDropping = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List(FallingTrashScene.assetNames, id: \.self) { assetName in
                Stepper(value: countBinding(for: assetName), in: 0...10) {
                    Text("\(assetName.replacingOccurrences(of: "temp_trash_", with: "")) \(assetCounts[assetName, default: 0])")
                }
            }
            .navigationTitle("쓰레기 선택")
            .toolbar {
                Button("시작") { isDropping = true }
                    .disabled(assetCounts.values.allSatisfy { $0 == 0 })
            }
            .navigationDestination(isPresented: $isDropping) {
                FallingTrashView(assetCounts: assetCounts)
            }
        }
    }

    // MARK: - Functions

    private func countBinding(for assetName: String) -> Binding<Int> {
        Binding(
            get: { assetCounts[assetName, default: 0] },
            set: { assetCounts[assetName] = $0 }
        )
    }
}
