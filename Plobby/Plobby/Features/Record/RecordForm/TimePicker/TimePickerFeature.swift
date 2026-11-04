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
        let latestTime: TimeOfDay?
        var meridiemWheel: WheelState<TimeOfDay.Meridiem>
        var hourWheel: WheelState<Int>
        var minuteWheel: WheelState<Int>
        
        init(
            field: PeriodField,
            date: Date,
            now: Date,
            calendar: Calendar
        ) {
            let isEndOfToday = field == .end && calendar.isDate(date, inSameDayAs: now)
            
            self.field = field
            self.baseDate = date
            self.latestTime = isEndOfToday ? TimeOfDay(date: now, calendar: calendar) : nil
            
            var time = TimeOfDay(date: date, calendar: calendar)
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
            applyLatestTime()
        }
        
        var selectedTime: TimeOfDay {
            TimeOfDay(
                meridiem: meridiemWheel.selectedValue,
                hour12: hourWheel.selectedValue,
                minute: minuteWheel.selectedValue
            )
        }
        
        mutating func applyLatestTime() {
            guard let latest = latestTime else {
                return
            }
            
            meridiemWheel.update(
                values: latest.meridiem == .am ? [.am] : TimePickerFeature.meridiems,
                isCyclic: false
            )
            
            if meridiemWheel.selectedValue == latest.meridiem {
                let hour12s = (latest.meridiem.startHour24...latest.hour24).map {
                    TimeOfDay(hour24: $0, minute: 0).hour12
                }
                hourWheel.update(values: hour12s, isCyclic: false)
            } else {
                hourWheel.update(values: TimePickerFeature.hours, isCyclic: true)
            }
            
            if meridiemWheel.selectedValue == latest.meridiem,
               hourWheel.selectedValue == latest.hour12 {
                minuteWheel.update(values: Array(0...latest.minute), isCyclic: false)
            } else {
                minuteWheel.update(values: TimePickerFeature.minutes, isCyclic: true)
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
                state.applyLatestTime()
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
