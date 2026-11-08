//
//  GoalTrashSummary.swift
//  Plobby
//
//  Created by dlsundn on 11/9/26.
//

import Foundation

nonisolated struct GoalTrashSummary: Identifiable, Equatable, Sendable {
    let category: TrashCategory
    let collectedCount: Int

    var id: TrashCategory { category }
}
