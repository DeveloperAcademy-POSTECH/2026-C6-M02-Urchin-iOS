//
//  PlobbyNavigationBarStyle.swift
//  Plobby
//
//  Created by 더스틴 on 11/10/26.
//

import SwiftUI

protocol PlobbyNavigationBarStyle {

    associatedtype Body: View

    @ViewBuilder
    func makeBody(configuration: PlobbyNavigationBarConfiguration) -> Body
}
