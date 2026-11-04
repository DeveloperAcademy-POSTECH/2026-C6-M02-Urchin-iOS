//
//  RecordFormFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RecordFormFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let recordType: RecordType
        var photos: IdentifiedArrayOf<PhotoAsset> = []
        var beach: Beach?
        var isLocationErrorVisible: Bool = false
        var period = ActivityPeriod()
        var periodError: String?
        var maxDepthText: String = ""
        var maxDepthError: String?
        var trash = TrashSelection()
        var totalWeightText: String = ""
        var totalWeightError: String?
        var memo: String = ""
        var isSubmitting: Bool = false
        var isCompleteEnabled: Bool = false
        @Presents var destination: Destination.State?

        var remainingPhotoCount: Int {
            max(RecordFormFeature.maxPhotoCount - photos.count, 0)
        }

        var isMemoOverLimit: Bool {
            memo.count > RecordMemo.maximumLength
        }
    }

    // MARK: - Destination

    @Reducer
    enum Destination {
        case photoPicker(PhotosPickerFeature)
        case locationPicker(LocationPickerFeature)
        case datePicker(DatePickerFeature)
        case timePicker(TimePickerFeature)
        case trashPicker(TrashPickerFeature)
        case alert(AlertState<Alert>)

        enum Alert {
            case retrySubmitTapped
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case closeTapped
        case cameraTapped
        case photoDeleteTapped(PhotoAsset.ID)
        case locationFieldTapped
        case dateTapped(PeriodField)
        case timeTapped(PeriodField)
        case maxDepthFocusChanged(isFocused: Bool)
        case totalWeightFocusChanged(isFocused: Bool)
        case trashFieldTapped
        case completeTapped
        case submitResponse(Result<UUID, any Error>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case recordCreated(UUID)
            case closed
        }
    }

    static let maxPhotoCount = 5

    // MARK: - Dependency

    // TODO: - 기록 저장 구현 시 recordClient.submitRecord 결과의 ID로 교체
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    @Dependency(\.locale) var locale

    // MARK: - Body

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce {
            state,
            action in
            switch action {
            case .binding(\.maxDepthText):
                state.maxDepthError = nil
                return .none
                
            case .binding(\.totalWeightText):
                state.totalWeightError = nil
                return .none
                
            case .closeTapped:
                return .send(.delegate(.closed))
                
            case .cameraTapped:
                guard state.remainingPhotoCount > 0 else {
                    return .none
                }
                
                state.destination = .photoPicker(PhotosPickerFeature.State(
                    maxSelectionCount: state.remainingPhotoCount
                ))
                return .none
                
            case let .photoDeleteTapped(id):
                state.photos.remove(id: id)
                return .none
                
            case .locationFieldTapped:
                state.destination = .locationPicker(LocationPickerFeature.State(
                    selectedBeach: state.beach
                ))
                return .none
                
            case let .dateTapped(field):
                state.destination = .datePicker(DatePickerFeature.State(
                    field: field,
                    date: state.period[field] ?? now,
                    today: now,
                    calendar: calendar
                ))
                return .none
                
            case let .timeTapped(field):
                state.destination = .timePicker(TimePickerFeature.State(
                    field: field,
                    date: state.period[field] ?? now,
                    now: now,
                    calendar: calendar
                ))
                return .none
                
            case .maxDepthFocusChanged(isFocused: true):
                return .none
                
            case .maxDepthFocusChanged(isFocused: false):
                state.maxDepthError = maxDepthError(for: state.maxDepthText)
                return .none
                
            case .totalWeightFocusChanged(isFocused: true):
                return .none
                
            case .totalWeightFocusChanged(isFocused: false):
                state.totalWeightError = totalWeightError(for: state.totalWeightText)
                return .none
                
            case .trashFieldTapped:
                state.destination = .trashPicker(TrashPickerFeature.State(
                    selection: state.trash
                ))
                return .none
                
            case .completeTapped:
                guard !state.isSubmitting,
                      validate(&state) else { return .none }
                
                state.isSubmitting = true
                return submit()
                
            case let .submitResponse(.success(recordID)):
                state.isSubmitting = false
                return .send(.delegate(.recordCreated(recordID)))
                
            case .submitResponse(.failure):
                state.isSubmitting = false
                state.destination = .alert(.make(
                    .recordSubmitFailed,
                    confirm: .retrySubmitTapped
                ))
                return .none
                
            case let .destination(.presented(.photoPicker(.delegate(.finished(photos))))):
                for photo in photos.prefix(state.remainingPhotoCount) {
                    state.photos.updateOrAppend(photo)
                }
                state.destination = nil
                return .none
                
            case .destination(.presented(.photoPicker(.delegate(.cancelled)))):
                state.destination = nil
                return .none
                
            case let .destination(.presented(.locationPicker(.delegate(.selected(beach))))):
                state.beach = beach
                state.isLocationErrorVisible = false
                state.destination = nil
                return .none
                
            case let .destination(.presented(.datePicker(.delegate(.confirmed(field, date))))):
                state.period[field] = calendar.date(on: date, settingTimeOf: state.period[field] ?? date)
                state.periodError = periodError(for: state.period)
                state.destination = nil
                return .none
                
            case let .destination(.presented(.timePicker(.delegate(.confirmed(field, time))))):
                state.period[field] = calendar.date(on: state.period[field] ?? now, settingTimeOf: time)
                state.periodError = periodError(for: state.period)
                state.destination = nil
                return .none
                
            case let .destination(.presented(.trashPicker(.delegate(.confirmed(selection))))):
                state.trash = selection
                state.destination = nil
                return .none
                
            case .destination(.presented(.alert(.retrySubmitTapped))):
                return .send(.completeTapped)
                
            // 선택하지 않고 시트를 닫으면 필수 항목 오류를 표시
            case .destination(.dismiss):
                switch state.destination {
                case .locationPicker:
                    state.isLocationErrorVisible = state.beach == nil
                case .datePicker, .timePicker:
                    state.periodError = periodError(for: state.period)
                default:
                    break
                }
                return .none
                
            case .binding,
                    .destination,
                    .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Reduce { state, _ in
            state.isCompleteEnabled = canComplete(state)
            return .none
        }
    }
}

// MARK: - Functions

extension RecordFormFeature {

    private func validate(_ state: inout State) -> Bool {
        state.isLocationErrorVisible = state.beach == nil
        state.periodError = periodError(for: state.period)
        state.maxDepthError = maxDepthError(for: state.maxDepthText)
        state.totalWeightError = totalWeightError(for: state.totalWeightText)

        return canComplete(state)
    }

    private func canComplete(_ state: State) -> Bool {
        guard !state.isSubmitting,
              state.beach != nil,
              periodError(for: state.period) == nil,
              maxDepthError(for: state.maxDepthText) == nil,
              totalWeightError(for: state.totalWeightText) == nil,
              !state.isMemoOverLimit
        else { return false }

        return true
    }

    private func periodError(for period: ActivityPeriod) -> String? {
        guard period.isComplete else {
            return "활동 날짜와 시간을 입력해주세요."
        }

        guard period.isValid else {
            return "종료 시간은 시작 시간보다 늦어야 해요."
        }

        return nil
    }

    private func maxDepthError(for text: String) -> String? {
        guard !InputText.isBlank(text) else { return nil }

        guard let meters = DecimalInput.number(
            from: text,
            locale: locale
        ) else {
            return "소수점 첫째 자리까지 숫자로 입력해 주세요."
        }

        guard WaterDepth.isValid(meters) else {
            return "\(WaterDepth.range.lowerBound)m부터 \(WaterDepth.range.upperBound)m까지 입력할 수 있어요."
        }

        return nil
    }

    private func totalWeightError(for text: String) -> String? {
        guard !InputText.isBlank(text) else { return nil }

        guard let kilograms = DecimalInput.number(from: text, locale: locale) else {
            return "소수점 첫째 자리까지 숫자로 입력해 주세요."
        }

        guard CollectedWeight.isValid(kilograms: kilograms) else {
            let range = CollectedWeight.kilogramsRange
            return "\(range.lowerBound)kg부터 \(range.upperBound)kg까지 입력할 수 있어요."
        }

        return nil
    }

    private func submit() -> Effect<Action> {
        let recordID = uuid()

        return .run { send in
            // TODO: NewRecord 구현 후 recordClient.submitRecord 호출로 교체
            await send(.submitResponse(.success(recordID)))
        }
    }
}

// MARK: - Conformance

extension RecordFormFeature.Destination.State: Equatable {}
