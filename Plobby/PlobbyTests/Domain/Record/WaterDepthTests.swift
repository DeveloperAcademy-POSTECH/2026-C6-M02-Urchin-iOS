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
    
    @Test
    func 최소_수심보다_얕으면_유효하지_않다() {
        #expect(WaterDepth.isValid(0) == false)
        #expect(WaterDepth.isValid(0.09) == false)
        #expect(WaterDepth.isValid(-1) == false)
    }
    
    @Test
    func 최대_수심보다_깊으면_유효하지_않다() {
        #expect(WaterDepth.isValid(100) == false)
        #expect(WaterDepth.isValid(99.91) == false)
    }
    
    @Test
    func 숫자가_아니면_유효하지_않다() {
        #expect(WaterDepth.isValid(.nan) == false)
        #expect(WaterDepth.isValid(.infinity) == false)
    }
}
