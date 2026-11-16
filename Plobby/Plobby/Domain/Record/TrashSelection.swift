//
//  TrashSelection.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct TrashSelection: Equatable, Sendable {
    
    /// 모든 카테고리를 합친 최대 개수예요.
    static let maximumTotalCount = 999
    static let etcMemoMaximumLength = 50

    private(set) var counts: [TrashCategory: Int] = [:]

    var etcMemo: String = ""

    /// 늘릴 때는 합계가 `maximumTotalCount`를 넘지 않게 맞추고, 줄일 때는 그대로 줄여요.
    subscript(category: TrashCategory) -> Int {
        get { counts[category, default: 0] }
        set {
            let current = self[category]
            let count = newValue > current
                ? min(newValue, max(maximumCount(for: category), current))
                : max(newValue, 0)
            counts[category] = count > 0 ? count : nil
            
            if category == .etc, count == 0 {
                etcMemo = ""
            }
        }
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

    var isFull: Bool {
        totalCount >= Self.maximumTotalCount
    }

    /// 다른 카테고리 개수를 빼고, 이 카테고리에 넣을 수 있는 최대 개수예요.
    func maximumCount(for category: TrashCategory) -> Int {
        max(Self.maximumTotalCount - (totalCount - self[category]), 0)
    }
    
    var summary: String? {
        let categories = selectedCategories
        guard let first = categories.max(by: { self[$0] < self[$1] }) else { return nil }
        
        let kinds = categories.count > 1 ? "\(first.name) 외 \(categories.count - 1)종" : first.name
        return "\(kinds), 총 \(totalCount)개"
    }
}
