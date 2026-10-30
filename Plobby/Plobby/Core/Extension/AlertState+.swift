//
//  AlertState+.swift
//  Plobby
//
//  Created by 더스틴 on 10/29/26.
//

import Foundation

import ComposableArchitecture

extension AlertState {
    static func make(
        _ type: AlertType,
        confirm confirmAction: Action? = nil,
        cancel cancelAction: Action? = nil
    ) -> Self {
        AlertState(
            title: {
                TextState(type.title)
            },
            actions: {
                return makeActions(.signInFailed)
            },
            message: type.message.map { message in
                { TextState(message) }
            }
        )
    }
    
    @ButtonStateBuilder<Action>
    private static func makeActions(
        _ type: AlertType,
        confirm confirmAction: Action? = nil,
        cancel cancelAction: Action? = nil
    ) -> [ButtonState<Action>] {
        switch type.buttonType {
        case .confirm: ButtonState.make(type.confirmTitle, action: confirmAction)
        }
    }
}
