//
//  Coordinate.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

nonisolated struct Coordinate: Equatable, Hashable, Sendable {
    
    var latitude: Double
    var longitude: Double
    
    /// 영일대 해수욕장: 위치 권한 거부 시 기본 위치
    static let fallback = Coordinate(latitude: 36.0566, longitude: 129.3786)
}
