//
//  DatePickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/4/26.
//

import SwiftUI

import ComposableArchitecture

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct DatePickerView: View {

    // MARK: - Properties

    let store: StoreOf<DatePickerFeature>

    @Environment(\.calendar) private var calendar

    private let weekdaySymbols = DayOfWeek.allCases.map { $0.koreanName }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private static let dayHeight: CGFloat = 44

    static func sheetHeight(weekCount: Int) -> CGFloat {
        236 + dayHeight * CGFloat(weekCount)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            dateSelectionTitle

            VStack(spacing: 6) {
                monthHeader
                weekdayHeader
                dayGrid
            }

            compeletionButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}

// MARK: - Subviews

private extension DatePickerView {
    
    var dateSelectionTitle: some View {
        Text(store.field.dateTitle)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Color.formPrimaryText)
            .frame(height: 28)
    }
    
    var compeletionButton: some View {
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

// MARK: - 월 이동

private extension DatePickerView {

    var monthHeader: some View {
        HStack(spacing: 0) {
            Text(monthTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)

            Spacer()

            monthButton(
                systemName: "chevron.left",
                accessibilityLabel: "이전 달",
                isEnabled: store.isPreviousMonthEnabled
            ) {
                store.send(.previousMonthTapped)
            }
            monthButton(
                systemName: "chevron.right",
                accessibilityLabel: "다음 달",
                isEnabled: store.isNextMonthEnabled
            ) {
                store.send(.nextMonthTapped)
            }
        }
        .frame(height: 44)
    }

    var monthTitle: String {
        let components = calendar.dateComponents([.year, .month], from: store.month)
        return "\(components.year ?? 0)년 \(components.month ?? 0)월"
    }

    func monthButton(
        systemName: String,
        accessibilityLabel: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isEnabled ? Color.formAccent : Color.formDisabledText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 달력

private extension DatePickerView {

    var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.formSecondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 22)
    }

    var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(store.days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear
                        .frame(height: Self.dayHeight)
                }
            }
        }
    }

    func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: store.date)
        let isToday = calendar.isDate(day, inSameDayAs: store.today)
        let isDisabled = !DatePickerFeature.isSelectable(day, in: store.allowedRange, calendar: calendar)

        return Button {
            store.send(.dayTapped(day))
        } label: {
            dayText(
                day: day,
                isSelected: isSelected,
                isToday: isToday,
                isDisabled: isDisabled
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    func dayText(
        day: Date,
        isSelected: Bool,
        isToday: Bool,
        isDisabled: Bool
    ) -> some View {
        Text("\(calendar.component(.day, from: day))")
            .font(.system(size: 18, weight: isToday && !isSelected ? .semibold : .regular))
            .foregroundStyle(
                dayColor(
                    isSelected: isSelected,
                    isToday: isToday,
                    isDisabled: isDisabled
                )
            )
            .frame(width: 36, height: 36)
            .background {
                if isSelected {
                    Circle()
                        .fill(Color.formAccent)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.dayHeight)
            .contentShape(Rectangle())
    }

    func dayColor(
        isSelected: Bool,
        isToday: Bool,
        isDisabled: Bool
    ) -> Color {
        if isSelected {
            return .white
        }
        if isDisabled {
            return .formDisabledText
        }
        if isToday {
            return .formToday
        }
        return .formPrimaryText
    }
}

// MARK: - Color

private extension Color {
    static let formToday = Color(red: 0x08 / 255, green: 0x7A / 255, blue: 0x54 / 255)
}
