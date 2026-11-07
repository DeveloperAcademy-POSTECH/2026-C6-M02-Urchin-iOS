//
//  CollectedWeight.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum CollectedWeight {
    
    static let kilogramsRange: ClosedRange<Double> = 0.1...999.9
    
    static func isValid(kilograms: Double) -> Bool {
        kilogramsRange.contains(kilograms)
    }
}
