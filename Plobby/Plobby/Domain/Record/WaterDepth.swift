//
//  WaterDepth.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum WaterDepth {
    
    static let range: ClosedRange<Double> = 0.1...99.9
    
    static func isValid(_ meters: Double) -> Bool {
        range.contains(meters)
    }
}
