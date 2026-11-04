//
//  TimePickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import SwiftUI

import ComposableArchitecture

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct TimePickerView: View {

    // MARK: - Properties

    let store: StoreOf<TimePickerFeature>

    static let sheetHeight: CGFloat = 298

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            timeSelectionTitle
            timePickers
            completionButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}

// MARK: - Subviews

private extension TimePickerView {
    
    var timeSelectionTitle: some View {
        Text(store.field.timeTitle)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.formPrimaryText)
            .frame(height: 28)
    }
    
    var timePickers: some View {
        HStack(spacing: 0) {
            wheelPicker(.meridiem, state: store.meridiemWheel) { meridiem in
                meridiem.rawValue
            }
            wheelPicker(.hour, state: store.hourWheel) { hour in
                "\(hour)"
            }
            wheelPicker(.minute, state: store.minuteWheel) { minute in
                String(format: "%02d", minute)
            }
        }
        .padding(.vertical, 10)
        .background(Color.formFieldBackground, in: RoundedRectangle(cornerRadius: 14))
    }
    
    func wheelPicker<Value: Hashable>(
        _ wheel: TimePickerFeature.Wheel,
        state: TimePickerFeature.WheelState<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        WheelPicker(
            rowCount: state.rowCount,
            selectedRow: state.row,
            label: { row in label(state.value(at: row)) },
            onScroll: { row in store.send(.wheelScrolled(wheel, row: row)) }
        )
    }

    var completionButton: some View {
        Button {
            store.send(.confirmTapped)
        } label: {
            Text("완료")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.formAccent, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WheelPicker

private struct WheelPicker: View {

    let rowCount: Int
    let selectedRow: Int
    let label: (Int) -> String
    let onScroll: (Int) -> Void

    private let rowHeight: CGFloat = 40
    private let visibleRowCount = 3

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { row in
                    rowText(row)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.vertical, rowHeight, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: scrollPosition)
        .frame(height: rowHeight * CGFloat(visibleRowCount))
        .frame(maxWidth: .infinity)
    }

    private var scrollPosition: Binding<Int?> {
        Binding(
            get: { selectedRow },
            set: { row in
                guard let row, row != selectedRow else {
                    return
                }
                onScroll(row)
            }
        )
    }

    private func rowText(_ row: Int) -> some View {
        let isSelected = row == selectedRow

        return Text(label(row))
            .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.formPrimaryText : Color.formSecondaryText.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: rowHeight)
    }
}
