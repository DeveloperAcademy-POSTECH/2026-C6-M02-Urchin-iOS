//
//  MemberNameTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct MemberNameTests {
    
    @Test
    func 한_글자_이름은_유효하다() {
        #expect(MemberName.isValid("은") == true)
    }
    
    @Test
    func 여섯_글자_이름은_유효하다() {
        #expect(MemberName.isValid("포항물잡이단") == true)
    }
    
    @Test
    func 일곱_글자_이상이면_유효하지_않다() {
        #expect(MemberName.isValid("포항물잡이단원") == false)
    }
    
    @Test
    func 비어_있거나_공백만_있으면_유효하지_않다() {
        #expect(MemberName.isValid("") == false)
        #expect(MemberName.isValid("   ") == false)
    }
    
    @Test
    func 앞뒤_공백은_길이에_포함하지_않는다() {
        #expect(MemberName.isValid("  포항물잡이단  ") == true)
    }
    
    @Test
    func 가운데_공백은_길이에_포함한다() {
        #expect(MemberName.isValid("포항 물잡이단") == false)
    }
}
