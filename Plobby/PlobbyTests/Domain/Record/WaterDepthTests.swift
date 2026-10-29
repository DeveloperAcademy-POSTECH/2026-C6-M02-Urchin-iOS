//
//  WaterDepthTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct WaterDepthTests {
    
    @Test
    func 최소_수심은_유효하다() {
        #expect(WaterDepth.isValid(0.1) == true)
    }
    
    @Test
    func 최대_수심은_유효하다() {
        #expect(WaterDepth.isValid(99.9) == true)
    }
    
    @Test
    func 범위_안의_수심은_유효하다() {
        #expect(WaterDepth.isValid(8.5) == true)
    }
    
    @Test(arguments: [0, 0.09, -1])
    func 최소_수심보다_얕으면_유효하지_않다(meters: Double) {
        #expect(WaterDepth.isValid(meters) == false)
    }
    
    @Test(arguments: [100, 99.91])
    func 최대_수심보다_깊으면_유효하지_않다(meters: Double) {
        #expect(WaterDepth.isValid(meters) == false)
    }
    
    @Test(arguments: [Double.nan, .infinity])
    func 숫자가_아니면_유효하지_않다(meters: Double) {
        #expect(WaterDepth.isValid(meters) == false)
    }
}
