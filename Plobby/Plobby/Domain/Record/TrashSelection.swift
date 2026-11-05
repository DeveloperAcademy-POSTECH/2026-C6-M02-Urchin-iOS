//
//  TrashSelection.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct TrashSelection: Equatable, Sendable {

    static let maximumCount = 999
    static let etcMemoMaximumLength = 50

    private(set) var counts: [TrashCategory: Int] = [:]

    var etcMemo: String = ""

    subscript(category: TrashCategory) -> Int {
        get { counts[category, default: 0] }
        set {
            let count = min(max(newValue, 0), Self.maximumCount)
            counts[category] = count > 0 ? count : nil

            if category == .etc, count == 0 {
                etcMemo = ""
            }
        }
    }
    
    var summary: String? {
        guard let first = items.first else { return nil }
        let kinds = items.count > 1 ? "\(first.name) 외 \(items.count - 1)종" : first.name
        return "\(kinds), 총 \(totalQuantity)개"
    }

    var selectedCategories: [TrashCategory] {
        TrashCategory.allCases.filter { self[$0] > 0 }
    }

    var isEmpty: Bool {
        counts.isEmpty
    }

    var totalCount: Int {
        counts.values.reduce(0, +)
    }
}
