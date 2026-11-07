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

    private static let dayHeight: CGFloat = 44.scaled

    static func sheetHeight(weekCount: Int) -> CGFloat {
        236.scaled + dayHeight * CGFloat(weekCount)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            dateSelectionTitle

            VStack(spacing: 6.scaled) {
                monthHeader
                weekdayHeader
                dayGrid
            }

            compeletionButton
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 20.scaled)
        .padding(.bottom, 24.scaled)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.gray0))
    }
}

// MARK: - Subviews

private extension DatePickerView {
    
    var dateSelectionTitle: some View {
        Text(store.field.dateTitle)
            .plobbyFont(.heading)
            .foregroundStyle(Color(.textPrimary))
            .frame(height: 28.scaled)
    }
    
    var compeletionButton: some View {
        Button {
            store.send(.confirmTapped)
        } label: {
            Text("완료")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity)
                .frame(height: 54.scaled)
                .background(Color(.green500), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 월 이동

private extension DatePickerView {

    var monthHeader: some View {
        HStack(spacing: 0) {
            Text(monthTitle)
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 18.scaled))
                .foregroundStyle(Color(.textPrimary))

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
        .frame(height: 44.scaled)
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
                .font(.system(size: 17.scaled, weight: .medium))
                .foregroundStyle(isEnabled ? Color(.green500) : Color(.textDisabled))
                .frame(width: 44.scaled, height: 44.scaled)
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
                    .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 13.scaled))
                    .foregroundStyle(Color(.textSecondary))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 22.scaled)
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
            .font(.custom((isToday && !isSelected ? PretendardWeight.semiBold : .regular).rawValue, fixedSize: 18.scaled))
            .foregroundStyle(
                dayColor(
                    isSelected: isSelected,
                    isToday: isToday,
                    isDisabled: isDisabled
                )
            )
            .frame(width: 36.scaled, height: 36.scaled)
            .background {
                if isSelected {
                    Circle()
                        .fill(Color(.green500))
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
            return Color(.gray0)
        }
        if isDisabled {
            return Color(.textDisabled)
        }
        if isToday {
            return Color(.currentBrandText)
        }
        return Color(.textPrimary)
    }
}
