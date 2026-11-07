//
//  ButtonState+.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import ComposableArchitecture

extension ButtonState {
    static func make(
        _ title: String,
        role: ButtonStateRole? = nil,
        action: Action?
    ) -> Self {
        guard let action else {
            return ButtonState(role: role) {
                TextState(title)
            }
        }
        
        return ButtonState(role: role, action: action) {
            TextState(title)
        }
    }
}
