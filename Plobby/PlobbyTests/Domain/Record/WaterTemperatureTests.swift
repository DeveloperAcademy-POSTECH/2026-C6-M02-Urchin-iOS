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
        #expect(WaterTemperature.isValid(0.0))
    }
    
    @Test
    func 최고_수온은_유효하다() {
        #expect(WaterTemperature.isValid(40.0))
    }
    
    @Test
    func 범위_안의_수온은_유효하다() {
        #expect(WaterTemperature.isValid(18.5))
    }
    
    @Test(arguments: [-0.1, -5])
    func 최저_수온보다_낮으면_유효하지_않다(celsius: Double) {
        #expect(!WaterTemperature.isValid(celsius))
    }
    
    @Test(arguments: [40.1, 100])
    func 최고_수온보다_높으면_유효하지_않다(celsius: Double) {
        #expect(!WaterTemperature.isValid(celsius))
    }
    
    @Test(arguments: [Double.nan, .infinity])
    func 숫자가_아니면_유효하지_않다(celsius: Double) {
        #expect(!WaterTemperature.isValid(celsius))
    }
}
