//
//  TrashSelection.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

nonisolated struct TrashSelection: Equatable, Sendable, Codable {
    
    var items: [Item] = []
    
    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    /// 예: "낚시·어업 용품 외 2종, 총 14개"
    var summary: String? {
        guard let first = items.first else { return nil }
        let kinds = items.count > 1 ? "\(first.name) 외 \(items.count - 1)종" : first.name
        return "\(kinds), 총 \(totalQuantity)개"
    }
}

extension TrashSelection {
    
    nonisolated struct Item: Equatable, Sendable, Codable {
        let name: String
        var quantity: Int
    }
}
