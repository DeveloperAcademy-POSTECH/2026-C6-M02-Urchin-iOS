//
//  TrashPickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct TrashPickerFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selection: TrashSelection
        var editingCategory: TrashCategory?
        var countText: String = ""

        init(selection: TrashSelection) {
            self.selection = selection
        }

        var guideText: String {
            selection.isEmpty
            ? "주운 쓰레기 종류를 추가해주세요."
            : "숫자를 눌러 개수를 바로 입력할 수 있어요."
        }

        var isEtcMemoVisible: Bool {
            selection[.etc] > 0
        }

        var isEtcMemoOverLimit: Bool {
            selection.etcMemo.count > TrashSelection.etcMemoMaximumLength
        }

        /// 유효성 검사를 모두 통과해야 완료할 수 있어요.
        var isCompleteEnabled: Bool {
            !isEtcMemoOverLimit
        }
    }

    // MARK: - Action

    enum Action {
        case plusTapped(TrashCategory)
        case minusTapped(TrashCategory)
        case countTapped(TrashCategory)
        case countTextChanged(TrashCategory, String)
        case countEditingEnded
        case etcMemoChanged(String)
        case cancelTapped
        case completeTapped
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case confirmed(TrashSelection)
            case cancelled
        }
    }

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .plusTapped(category):
                commitCountEditing(&state)
                state.selection[category] += 1
                return .none

            case let .minusTapped(category):
                commitCountEditing(&state)
                state.selection[category] -= 1
                return .none

            case let .countTapped(category):
                guard state.editingCategory != category else { return .none }

                commitCountEditing(&state)
                state.editingCategory = category
                state.countText = "\(state.selection[category])"
                return .none

            case let .countTextChanged(category, text):
                guard state.editingCategory == category else { return .none }

                let digits = String(text.filter(\.isASCIIDigit).prefix(Self.maximumCountDigits))
                state.countText = digits

                if let count = Int(digits), count > 0 {
                    state.selection[category] = count
                }
                return .none

            case .countEditingEnded:
                commitCountEditing(&state)
                return .none

            case let .etcMemoChanged(memo):
                guard state.isEtcMemoVisible else { return .none }

                state.selection.etcMemo = memo
                return .none

            case .cancelTapped:
                return .send(.delegate(.cancelled))

            case .completeTapped:
                guard state.isCompleteEnabled else { return .none }

                commitCountEditing(&state)
                return .send(.delegate(.confirmed(state.selection)))

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension TrashPickerFeature {

    private static let maximumCountDigits = String(TrashSelection.maximumCount).count

    private func commitCountEditing(_ state: inout State) {
        guard let category = state.editingCategory else { return }

        state.selection[category] = Int(state.countText) ?? 0
        state.editingCategory = nil
        state.countText = ""
    }
}
