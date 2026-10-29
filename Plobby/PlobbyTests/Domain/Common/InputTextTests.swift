//
//  InputTextTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct InputTextTests {
    
    // MARK: - trimmed
    
    @Test
    func 앞뒤_공백을_제거한다() {
        #expect(InputText.trimmed("  포항물잡이  ") == "포항물잡이")
    }
    
    @Test
    func 앞뒤_줄바꿈과_탭을_제거한다() {
        #expect(InputText.trimmed("\n\t포항물잡이\n") == "포항물잡이")
    }
    
    @Test
    func 가운데_공백은_유지한다() {
        #expect(InputText.trimmed(" 해녀와 바다 ") == "해녀와 바다")
    }
    
    @Test
    func 전각_공백도_제거한다() {
        #expect(InputText.trimmed("\u{3000}포항\u{3000}") == "포항")
    }
    
    @Test
    func 빈_문자열은_빈_문자열을_반환한다() {
        #expect(InputText.trimmed("") == "")
    }
    
    // MARK: - isBlank
    
    @Test
    func 빈_문자열은_빈_값이다() {
        #expect(InputText.isBlank(""))
    }
    
    @Test
    func 공백만_있으면_빈_값이다() {
        #expect(InputText.isBlank("   "))
    }
    
    @Test
    func 줄바꿈과_탭만_있으면_빈_값이다() {
        #expect(InputText.isBlank("\n\t "))
    }
    
    @Test
    func 글자가_하나라도_있으면_빈_값이_아니다() {
        #expect(!InputText.isBlank(" 가 "))
    }
}
