//
//  HomeGoalBoard.swift
//  Plobby
//
//  Created by 더스틴 on 11/10/26.
//

struct HomeGoalBoard: Equatable, Sendable {
    
    let goal: Goal
    let recordType: RecordType
    let days: [GoalDailyProgress]
    let trashSummaries: [GoalTrashSummary]
    let participants: [GoalParticipant]
    
    var totalTrashCount: Int {
        trashSummaries.reduce(0) { $0 + $1.collectedCount }
    }
    
    var orderedTrashSummaries: [GoalTrashSummary] {
        trashSummaries.sorted {
            (TrashCategory.allCases.firstIndex(of: $0.category) ?? 0) < (TrashCategory.allCases.firstIndex(of: $1.category) ?? 0)
        }
    }
    
    var participantCount: Int {
        goal.participantCount(for: recordType)
    }
    
    var participantCollectedCount: Int {
        goal.collectedCount(for: recordType)
    }
    
    var rankedParticipants: [HomeRankedParticipant] {
        participants.map { participant in
            let rank = (participants.firstIndex {
                $0.collectedCount == participant.collectedCount
            } ?? 0) + 1
            
            return HomeRankedParticipant(rank: rank, participant: participant)
        }
    }
}
