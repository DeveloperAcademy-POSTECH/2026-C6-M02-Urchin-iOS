//
//  RecordMemoTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct RecordMemoTests {
    
    @Test
    func 비어_있거나_공백만_있어도_유효하다() {
        #expect(RecordMemo.isValid("") == true)
        #expect(RecordMemo.isValid("   ") == true)
    }
    
    @Test
    func 오백_글자_메모는_유효하다() {
        #expect(RecordMemo.isValid(String(repeating: "가", count: 500)) == true)
    }
    
    @Test
    func 오백한_글자_이상이면_유효하지_않다() {
        #expect(RecordMemo.isValid(String(repeating: "가", count: 501)) == false)
    }
    
    @Test
    func 앞뒤_공백은_길이에_포함하지_않는다() {
        #expect(RecordMemo.isValid("  " + String(repeating: "가", count: 500) + "\n") == true)
    }
    
    @Test
    func 가운데_공백과_줄바꿈은_길이에_포함한다() {
        #expect(RecordMemo.isValid(String(repeating: "가", count: 250) + " " + String(repeating: "가", count: 250)) == false)
        #expect(RecordMemo.isValid(String(repeating: "가", count: 250) + "\n" + String(repeating: "가", count: 250)) == false)
    }
    
    @Test
    func 이모지가_아닌_문자는_모두_허용한다() {
        #expect(RecordMemo.isValid("Plastic 3개, 수심 8.5m! (맑음) #1") == true)
    }
    
    @Test
    func 이모지가_있으면_유효하지_않다() {
        #expect(RecordMemo.isValid("바다가 맑았다🌊") == false)
        #expect(RecordMemo.isValid("최고👍🏻") == false)
        #expect(RecordMemo.isValid("1️⃣번 구역") == false)
    }
}
