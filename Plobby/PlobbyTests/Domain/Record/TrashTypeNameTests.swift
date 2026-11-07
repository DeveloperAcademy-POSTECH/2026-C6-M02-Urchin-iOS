//
//  TrashTypeNameTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct TrashTypeNameTests {
    
    @Test
    func 한_글자_쓰레기_종류는_유효하다() {
        #expect(TrashTypeName.isValid("캔"))
    }
    
    @Test
    func 스무_글자_쓰레기_종류는_유효하다() {
        #expect(TrashTypeName.isValid(String(repeating: "가", count: 20)))
    }
    
    @Test
    func 스물한_글자_이상이면_유효하지_않다() {
        #expect(!TrashTypeName.isValid(String(repeating: "가", count: 21)))
    }
    
    @Test(arguments: ["", "   "])
    func 비어_있거나_공백만_있으면_유효하지_않다(name: String) {
        #expect(!TrashTypeName.isValid(name))
    }
    
    @Test
    func 앞뒤_공백은_길이에_포함하지_않는다() {
        #expect(TrashTypeName.isValid("  " + String(repeating: "가", count: 20) + "  "))
    }
    
    @Test
    func 가운데_공백은_길이에_포함한다() {
        #expect(!TrashTypeName.isValid(String(repeating: "가", count: 10) + " " + String(repeating: "가", count: 10)))
    }
    
    @Test
    func 한글_영문_숫자_띄어쓰기_가운뎃점은_허용한다() {
        #expect(TrashTypeName.isValid("PET 병·캔 2"))
    }
    
    @Test(arguments: ["병/캔", "병.캔", "병🍾"])
    func 가운뎃점_외_특수문자와_이모지는_허용하지_않는다(name: String) {
        #expect(!TrashTypeName.isValid(name))
    }
}
