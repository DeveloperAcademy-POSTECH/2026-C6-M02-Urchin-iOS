//
//  WaterTemperature.swift
//  Plobby
//
//  Created by 이은지 on 10/26/26.
//

import Foundation

enum WaterTemperature {
    
    static let range: ClosedRange<Double> = 0.0...40.0
    
    static func isValid(_ celsius: Double) -> Bool {
        range.contains(celsius)
    }
}
