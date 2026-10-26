//
//  NicknameTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct NicknameTests {
    
    @Test
    func 한_글자_닉네임은_유효하지_않다() {
        #expect(Nickname.isValid("포") == false)
    }
    
    @Test
    func 두_글자_닉네임은_유효하다() {
        #expect(Nickname.isValid("포항") == true)
    }
    
    @Test
    func 오십_글자_닉네임은_유효하다() {
        #expect(Nickname.isValid(String(repeating: "가", count: 50)) == true)
    }
    
    @Test
    func 오십한_글자_이상이면_유효하지_않다() {
        #expect(Nickname.isValid(String(repeating: "가", count: 51)) == false)
    }
    
    @Test
    func 비어_있거나_공백만_있으면_유효하지_않다() {
        #expect(Nickname.isValid("") == false)
        #expect(Nickname.isValid("   ") == false)
    }
    
    @Test
    func 앞뒤_공백은_길이에_포함하지_않는다() {
        #expect(Nickname.isValid(" 포 ") == false)
        #expect(Nickname.isValid(" 포항 ") == true)
    }
    
    @Test
    func 가운데_공백은_길이에_포함한다() {
        #expect(Nickname.isValid("포 항") == true)
    }
}
