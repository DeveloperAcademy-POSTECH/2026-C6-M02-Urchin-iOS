//
//  CollectedWeightTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct CollectedWeightTests {
    
    @Test
    func 최소_무게는_유효하다() {
        #expect(CollectedWeight.isValid(kilograms: 0.1) == true)
    }
    
    @Test
    func 최대_무게는_유효하다() {
        #expect(CollectedWeight.isValid(kilograms: 999.9) == true)
    }
    
    @Test
    func 범위_안의_무게는_유효하다() {
        #expect(CollectedWeight.isValid(kilograms: 12.5) == true)
    }
    
    @Test
    func 최소_무게보다_가벼우면_유효하지_않다() {
        #expect(CollectedWeight.isValid(kilograms: 0) == false)
        #expect(CollectedWeight.isValid(kilograms: 0.09) == false)
        #expect(CollectedWeight.isValid(kilograms: -1) == false)
    }
    
    @Test
    func 최대_무게보다_무거우면_유효하지_않다() {
        #expect(CollectedWeight.isValid(kilograms: 1000) == false)
        #expect(CollectedWeight.isValid(kilograms: 999.91) == false)
    }
    
    @Test
    func 숫자가_아니면_유효하지_않다() {
        #expect(CollectedWeight.isValid(kilograms: .nan) == false)
        #expect(CollectedWeight.isValid(kilograms: .infinity) == false)
    }
}
