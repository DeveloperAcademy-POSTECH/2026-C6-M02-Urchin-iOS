//
//  DecimalInputTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Foundation
import Testing
@testable import Plobby

struct DecimalInputTests {
    
    private let koreanLocale = Locale(identifier: "ko_KR")
    private let germanLocale = Locale(identifier: "de_DE")
    
    @Test
    func 정수를_변환한다() {
        #expect(DecimalInput.number(from: "8", locale: koreanLocale) == 8)
    }
    
    @Test
    func 소수점_첫째_자리까지_변환한다() {
        #expect(DecimalInput.number(from: "8.5", locale: koreanLocale) == 8.5)
    }
    
    @Test
    func 소수점_둘째_자리부터는_변환하지_않는다() {
        #expect(DecimalInput.number(from: "8.55", locale: koreanLocale) == nil)
    }
    
    @Test
    func 기기_지역의_소수점_기호를_따른다() {
        #expect(DecimalInput.number(from: "8,5", locale: germanLocale) == 8.5)
        #expect(DecimalInput.number(from: "8,5", locale: koreanLocale) == nil)
    }
    
    @Test
    func 앞뒤_공백은_무시한다() {
        #expect(DecimalInput.number(from: " 8.5 ", locale: koreanLocale) == 8.5)
    }
    
    @Test
    func 비어_있거나_공백만_있으면_변환하지_않는다() {
        #expect(DecimalInput.number(from: "", locale: koreanLocale) == nil)
        #expect(DecimalInput.number(from: "   ", locale: koreanLocale) == nil)
    }
    
    @Test
    func 숫자가_아닌_문자가_있으면_변환하지_않는다() {
        #expect(DecimalInput.number(from: "8a", locale: koreanLocale) == nil)
        #expect(DecimalInput.number(from: "-1", locale: koreanLocale) == nil)
        #expect(DecimalInput.number(from: "1,000", locale: koreanLocale) == nil)
        #expect(DecimalInput.number(from: "½", locale: koreanLocale) == nil)
    }
    
    @Test
    func 소수점_앞이나_뒤가_비어_있으면_변환하지_않는다() {
        #expect(DecimalInput.number(from: ".5", locale: koreanLocale) == nil)
        #expect(DecimalInput.number(from: "8.", locale: koreanLocale) == nil)
    }
    
    @Test
    func 소수점이_두_개_이상이면_변환하지_않는다() {
        #expect(DecimalInput.number(from: "8.5.1", locale: koreanLocale) == nil)
    }
}
