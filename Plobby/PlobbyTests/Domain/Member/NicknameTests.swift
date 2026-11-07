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
        #expect(!Nickname.isValid("포"))
    }
    
    @Test
    func 두_글자_닉네임은_유효하다() {
        #expect(Nickname.isValid("포항"))
    }
    
    @Test
    func 열_글자_닉네임은_유효하다() {
        #expect(Nickname.isValid(String(repeating: "가", count: 10)))
    }
    
    @Test
    func 열한_글자_이상이면_유효하지_않다() {
        #expect(!Nickname.isValid(String(repeating: "가", count: 11)))
    }
    
    @Test(arguments: ["", "   "])
    func 비어_있거나_공백만_있으면_유효하지_않다(nickname: String) {
        #expect(!Nickname.isValid(nickname))
    }
    
    @Test
    func 앞뒤_공백은_길이에_포함하지_않는다() {
        #expect(!Nickname.isValid(" 포 "))
        #expect(Nickname.isValid(" 포항 "))
    }
    
    @Test
    func 한글_영문_숫자는_허용한다() {
        #expect(Nickname.isValid("포항Diver1"))
    }
    
    @Test
    func 띄어쓰기는_허용하지_않는다() {
        #expect(!Nickname.isValid("포 항"))
    }
    
    @Test(arguments: ["포항_다이버", "포항🐟"])
    func 특수문자와_이모지는_허용하지_않는다(nickname: String) {
        #expect(!Nickname.isValid(nickname))
    }
    
    @Test
    func 자음이나_모음만_있으면_허용하지_않는다() {
        #expect(!Nickname.isValid("ㅋㅋ"))
    }
    
    @Test
    func 전각_영문과_숫자는_허용하지_않는다() {
        #expect(!Nickname.isValid("ＡＢ１"))
    }
}
