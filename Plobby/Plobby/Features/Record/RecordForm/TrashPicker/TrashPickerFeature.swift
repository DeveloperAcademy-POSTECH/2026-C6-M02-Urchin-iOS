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
        var isCountOverLimit = false
        var isEtcMemoOverLimit = false

        init(selection: TrashSelection) {
            self.selection = selection
        }

        /// 직접 입력이 한도를 넘었거나, 합계가 한도에 닿아 더 늘릴 수 없을 때예요.
        var isLimitReached: Bool {
            isCountOverLimit || selection.isFull
        }

        var guideText: String {
            if isLimitReached {
                return "쓰레기는 총 \(TrashSelection.maximumTotalCount)개까지 입력할 수 있어요."
            }

            return selection.isEmpty
            ? "주운 쓰레기 종류를 골라 주세요"
            : "숫자를 누르면 개수를 바로 입력할 수 있어요"
        }

        var isEtcMemoVisible: Bool {
            selection[.etc] > 0
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

                let allDigits = text.filter(\.isASCIIDigit)
                let digits = String(allDigits.prefix(Self.maximumCountDigits))
                let maximumCount = state.selection.maximumCount(for: category)
                let isOverTotal = (Int(digits) ?? 0) > maximumCount
                state.isCountOverLimit = allDigits.count > Self.maximumCountDigits || isOverTotal
                state.countText = text
                state.countText = isOverTotal ? "\(maximumCount)" : digits

                if let count = Int(state.countText), count > 0 {
                    state.selection[category] = count
                }
                return .none

            case .countEditingEnded:
                commitCountEditing(&state)
                return .none

            case let .etcMemoChanged(memo):
                guard state.isEtcMemoVisible else { return .none }

                state.selection.etcMemo = memo
                state.isEtcMemoOverLimit = memo.count > TrashSelection.etcMemoMaximumLength
                if state.isEtcMemoOverLimit {
                    state.selection.etcMemo = String(memo.prefix(TrashSelection.etcMemoMaximumLength))
                }
                return .none

            case .cancelTapped:
                return .send(.delegate(.cancelled))

            case .completeTapped:
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

    private static let maximumCountDigits = String(TrashSelection.maximumTotalCount).count

    private func commitCountEditing(_ state: inout State) {
        guard let category = state.editingCategory else { return }

        state.selection[category] = Int(state.countText) ?? 0
        state.editingCategory = nil
        state.countText = ""
        state.isCountOverLimit = false
    }
}
