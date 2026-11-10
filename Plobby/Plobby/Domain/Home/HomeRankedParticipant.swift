//
//  HomeRankedParticipant.swift
//  Plobby
//
//  Created by 더스틴 on 11/10/26.
//

struct HomeRankedParticipant: Identifiable, Equatable, Sendable {
    
    let rank: Int
    let participant: GoalParticipant

    var id: GoalParticipant.ID { participant.id }
}
