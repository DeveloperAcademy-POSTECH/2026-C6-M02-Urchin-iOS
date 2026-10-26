//
//  WaterTemperatureTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct WaterTemperatureTests {
    
    @Test
    func 최저_수온은_유효하다() {
        #expect(WaterTemperature.isValid(0.0) == true)
    }
    
    @Test
    func 최고_수온은_유효하다() {
        #expect(WaterTemperature.isValid(40.0) == true)
    }
    
    @Test
    func 범위_안의_수온은_유효하다() {
        #expect(WaterTemperature.isValid(18.5) == true)
    }
    
    @Test
    func 최저_수온보다_낮으면_유효하지_않다() {
        #expect(WaterTemperature.isValid(-0.1) == false)
        #expect(WaterTemperature.isValid(-5) == false)
    }
    
    @Test
    func 최고_수온보다_높으면_유효하지_않다() {
        #expect(WaterTemperature.isValid(40.1) == false)
        #expect(WaterTemperature.isValid(100) == false)
    }
    
    @Test
    func 숫자가_아니면_유효하지_않다() {
        #expect(WaterTemperature.isValid(.nan) == false)
        #expect(WaterTemperature.isValid(.infinity) == false)
    }
}
