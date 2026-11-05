//
//  TimePickerFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct TimePickerFeature {
    
    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let field: PeriodField
        let baseDate: Date
        let earliestTime: TimeOfDay?
        let latestTime: TimeOfDay?
        var meridiemWheel: WheelState<TimeOfDay.Meridiem>
        var hourWheel: WheelState<Int>
        var minuteWheel: WheelState<Int>
        
        init(
            field: PeriodField,
            date: Date,
            allowedRange: ClosedRange<Date>,
            calendar: Calendar
        ) {
            self.field = field
            self.baseDate = date
            self.earliestTime = calendar.isDate(date, inSameDayAs: allowedRange.lowerBound)
                ? TimeOfDay(date: allowedRange.lowerBound, calendar: calendar)
                : nil
            self.latestTime = calendar.isDate(date, inSameDayAs: allowedRange.upperBound)
                ? TimeOfDay(date: allowedRange.upperBound, calendar: calendar)
                : nil
            
            var time = TimeOfDay(date: date, calendar: calendar)
            if let earliestTime, time < earliestTime {
                time = earliestTime
            }
            if let latestTime, time > latestTime {
                time = latestTime
            }
            
            self.meridiemWheel = WheelState(
                values: TimePickerFeature.meridiems,
                isCyclic: false,
                selected: time.meridiem
            )
            self.hourWheel = WheelState(
                values: TimePickerFeature.hours,
                isCyclic: true,
                selected: time.hour12
            )
            self.minuteWheel = WheelState(
                values: TimePickerFeature.minutes,
                isCyclic: true,
                selected: time.minute
            )
            applyBounds()
        }
        
        var selectedTime: TimeOfDay {
            TimeOfDay(
                meridiem: meridiemWheel.selectedValue,
                hour12: hourWheel.selectedValue,
                minute: minuteWheel.selectedValue
            )
        }
        
        mutating func applyBounds() {
            let earliest = earliestTime ?? TimeOfDay(hour24: 0, minute: 0)
            let latest = latestTime ?? TimeOfDay(hour24: 23, minute: 59)
            
            let meridiems = TimePickerFeature.meridiems.filter { meridiem in
                meridiem.startHour24 <= latest.hour24
                    && meridiem.startHour24 + TimeOfDay.hoursPerPeriod > earliest.hour24
            }
            meridiemWheel.update(values: meridiems, isCyclic: false)
            
            let meridiem = meridiemWheel.selectedValue
            let firstHour24 = max(meridiem.startHour24, earliest.hour24)
            let lastHour24 = min(meridiem.startHour24 + TimeOfDay.hoursPerPeriod - 1, latest.hour24)
            
            if lastHour24 - firstHour24 + 1 == TimeOfDay.hoursPerPeriod {
                hourWheel.update(values: TimePickerFeature.hours, isCyclic: true)
            } else {
                let hour12s = (firstHour24...lastHour24).map { TimeOfDay(hour24: $0, minute: 0).hour12 }
                hourWheel.update(values: hour12s, isCyclic: false)
            }
            
            let hour24 = TimeOfDay(meridiem: meridiem, hour12: hourWheel.selectedValue, minute: 0).hour24
            let firstMinute = hour24 == earliest.hour24 ? earliest.minute : 0
            let lastMinute = hour24 == latest.hour24 ? latest.minute : 59
            
            if firstMinute == 0, lastMinute == 59 {
                minuteWheel.update(values: TimePickerFeature.minutes, isCyclic: true)
            } else {
                minuteWheel.update(values: Array(firstMinute...lastMinute), isCyclic: false)
            }
        }
    }
    
    // MARK: - Action
    
    enum Action {
        case wheelScrolled(Wheel, row: Int)
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
        Reduce { state, action in
            switch action {
            case let .wheelScrolled(wheel, row):
                switch wheel {
                case .meridiem: state.meridiemWheel.row = row
                case .hour: state.hourWheel.row = row
                case .minute: state.minuteWheel.row = row
                }
                state.applyBounds()
                return .none
                
            case .confirmTapped:
                let time = calendar.date(
                    on: state.baseDate,
                    hour: state.selectedTime.hour24,
                    minute: state.selectedTime.minute
                )
                return .send(.delegate(.confirmed(state.field, time)))
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Wheel

extension TimePickerFeature {
    
    static let meridiems = TimeOfDay.Meridiem.allCases
    static let hours = Array(1...12)
    static let minutes = Array(0...59)
    
    enum Wheel {
        case meridiem
        case hour
        case minute
    }
    
    struct WheelState<Value: Hashable>: Equatable {
        private(set) var values: [Value]
        private(set) var isCyclic: Bool
        var row: Int
        
        private static var cyclicRepeatCount: Int { 100 }
        
        init(values: [Value], isCyclic: Bool, selected value: Value) {
            self.values = values
            self.isCyclic = isCyclic
            self.row = 0
            self.row = rowIndex(for: value)
        }
        
        var rowCount: Int {
            values.count * (isCyclic ? Self.cyclicRepeatCount : 1)
        }
        
        var selectedValue: Value {
            value(at: row)
        }
        
        func value(at row: Int) -> Value {
            values[row % values.count]
        }
        
        mutating func update(values newValues: [Value], isCyclic newIsCyclic: Bool) {
            guard newValues != values || newIsCyclic != isCyclic else {
                return
            }
            
            let selected: Value
            
            if newValues.contains(selectedValue) {
                selected = selectedValue
            } else {
                selected = newValues.last ?? selectedValue
            }
            
            values = newValues
            isCyclic = newIsCyclic
            row = rowIndex(for: selected)
        }
        
        private func rowIndex(for value: Value) -> Int {
            let index = values.firstIndex(of: value) ?? 0
            
            if isCyclic {
                return index + values.count * (Self.cyclicRepeatCount / 2)
            }
            return index
        }
    }
}
