//
//  DatePickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct DatePickerFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let field: PeriodField
        let today: Date
        let allowedRange: ClosedRange<Date>
        var date: Date
        var month: Date
        var days: [Date?]
        var isPreviousMonthEnabled: Bool
        var isNextMonthEnabled: Bool
        
        init(
            field: PeriodField,
            date: Date,
            today: Date,
            allowedRange: ClosedRange<Date>,
            calendar: Calendar
        ) {
            let date = date.clamped(to: allowedRange)
            let month = DatePickerFeature.startOfMonth(for: date, calendar: calendar)
            
            self.field = field
            self.today = today
            self.allowedRange = allowedRange
            self.date = date
            self.month = month
            self.days = DatePickerFeature.days(in: month, calendar: calendar)
            self.isPreviousMonthEnabled = DatePickerFeature.isPreviousMonthEnabled(
                month: month,
                allowedRange: allowedRange,
                calendar: calendar
            )
            self.isNextMonthEnabled = DatePickerFeature.isNextMonthEnabled(
                month: month,
                allowedRange: allowedRange,
                calendar: calendar
            )
        }
        
        var weekCount: Int {
            days.count / daysOfWeek
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case dayTapped(Date)
        case previousMonthTapped
        case nextMonthTapped
        case confirmTapped
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case confirmed(PeriodField, Date)
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.calendar) var calendar
    
    // MARK: - body
    
    var body: some Reducer<State, Action> {
        Reduce {
            state,
            action in
            switch action {
            case let .dayTapped(day):
                guard Self.isSelectable(day, in: state.allowedRange, calendar: calendar) else {
                    return .none
                }
                
                state.date = calendar.date(
                    on: day,
                    settingTimeOf: state.date
                ).clamped(to: state.allowedRange)
                return .none
                
            case .previousMonthTapped:
                if state.isPreviousMonthEnabled {
                    moveMonth(by: -1, state: &state)
                }
                
                return .none
                
            case .nextMonthTapped:
                if state.isNextMonthEnabled {
                    moveMonth(by: 1, state: &state)
                }
                
                return .none
                
            case .confirmTapped:
                return .send(.delegate(.confirmed(state.field, state.date)))
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension DatePickerFeature {
    
    private static let daysOfWeek = 7
    
    private func moveMonth(by value: Int, state: inout State) {
        guard let month = calendar.date(
            byAdding: .month,
            value: value,
            to: state.month
        ) else {
            return
        }
        
        state.month = month
        state.days = Self.days(in: month, calendar: calendar)
        state.isPreviousMonthEnabled = Self.isPreviousMonthEnabled(
            month: month,
            allowedRange: state.allowedRange,
            calendar: calendar
        )
        state.isNextMonthEnabled = Self.isNextMonthEnabled(
            month: month,
            allowedRange: state.allowedRange,
            calendar: calendar
        )
    }

    static func isSelectable(
        _ day: Date,
        in allowedRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Bool {
        calendar.compare(day, to: allowedRange.lowerBound, toGranularity: .day) != .orderedAscending
            && calendar.compare(day, to: allowedRange.upperBound, toGranularity: .day) != .orderedDescending
    }
    
    static func isPreviousMonthEnabled(
        month: Date,
        allowedRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Bool {
        startOfMonth(for: allowedRange.lowerBound, calendar: calendar) < month
    }
    
    static func isNextMonthEnabled(
        month: Date,
        allowedRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Bool {
        month < startOfMonth(for: allowedRange.upperBound, calendar: calendar)
    }
    
    static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }
    
    static func days(in month: Date, calendar: Calendar) -> [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }
        
        let leadingCount = calendar.component(.weekday, from: month) - 1
        let monthDays: [Date?] = dayRange.map { day in
            calendar.date(byAdding: .day, value: day - 1, to: month)
        }
        let days = Array(repeating: nil, count: leadingCount) + monthDays
        let trailingCount = (daysOfWeek - days.count % daysOfWeek) % daysOfWeek
        
        return days + Array(repeating: nil, count: trailingCount)
    }
}
