//
//  OrganizationNameTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 10/26/26.
//

import Testing
@testable import Plobby

struct OrganizationNameTests {
    
    @Test
    func 한_글자_단체명은_유효하다() {
        #expect(OrganizationName.isValid("포") == true)
    }
    
    @Test
    func 스무_글자_단체명은_유효하다() {
        #expect(OrganizationName.isValid(String(repeating: "가", count: 20)) == true)
    }
    
    @Test
    func 스물한_글자_이상이면_유효하지_않다() {
        #expect(OrganizationName.isValid(String(repeating: "가", count: 21)) == false)
    }
    
    @Test
    func 비어_있거나_공백만_있으면_유효하지_않다() {
        #expect(OrganizationName.isValid("") == false)
        #expect(OrganizationName.isValid("   ") == false)
    }
    
    @Test
    func 앞뒤_공백은_길이에_포함하지_않는다() {
        #expect(OrganizationName.isValid("  " + String(repeating: "가", count: 20) + "  ") == true)
    }
    
    @Test
    func 가운데_공백은_길이에_포함한다() {
        #expect(OrganizationName.isValid(String(repeating: "가", count: 10) + " " + String(repeating: "가", count: 10)) == false)
    }
    
    @Test
    func 한글_영문_숫자_띄어쓰기는_허용한다() {
        #expect(OrganizationName.isValid("포항 Ocean 1팀") == true)
    }
    
    @Test
    func 특수문자와_이모지는_허용하지_않는다() {
        #expect(OrganizationName.isValid("포항-바다") == false)
        #expect(OrganizationName.isValid("포항·바다") == false)
        #expect(OrganizationName.isValid("포항🌊") == false)
    }
    
    @Test
    func 가운데_줄바꿈은_허용하지_않는다() {
        #expect(OrganizationName.isValid("포항\n바다") == false)
    }
}
