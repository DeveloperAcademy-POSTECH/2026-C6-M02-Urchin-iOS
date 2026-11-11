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
        let mode: Mode
        private(set) var initialInputs: Inputs
        var photos: IdentifiedArrayOf<RecordPhoto>
        var beach: Beach?
        var isLocationErrorVisible: Bool = false
        var period: ActivityPeriod
        var periodError: String?
        var maxDepthText: String
        var maxDepthError: String?
        var trash: TrashSelection
        var totalWeightText: String
        var totalWeightError: String?
        var memo: String
        var isMemoErrorVisible: Bool = false
        var isMemoOverLimit: Bool = false
        var isSubmitting: Bool = false
        var isCompleteEnabled: Bool = false
        @Presents var destination: Destination.State?
        
        init(
            recordType: RecordType,
            mode: Mode = .create,
            photos: IdentifiedArrayOf<RecordPhoto> = [],
            beach: Beach? = nil,
            period: ActivityPeriod = ActivityPeriod(),
            maxDepthText: String = "",
            trash: TrashSelection = TrashSelection(),
            totalWeightText: String = "",
            memo: String = ""
        ) {
            self.recordType = recordType
            self.mode = mode
            self.photos = photos
            self.beach = beach
            self.period = period
            self.maxDepthText = maxDepthText
            self.trash = trash
            self.totalWeightText = totalWeightText
            self.memo = memo
            self.initialInputs = Inputs()
            self.initialInputs = inputs
            self.isCompleteEnabled = mode != .create
        }
        
        var title: String {
            switch mode {
            case .create: recordType.title
            case .edit: "\(recordType.name) 기록 수정하기"
            }
        }

        var remainingPhotoCount: Int {
            max(RecordFormFeature.maxPhotoCount - photos.count, 0)
        }

        /// 5장이 꽉 차도 앨범에서 고른 사진이 있으면 들어가서 바꿀 수 있어요.
        /// 수정 중인 기존 사진만으로 꽉 차 있으면 앨범에서 바꿀 사진이 없어서 막아요.
        var canOpenPhotoPicker: Bool {
            remainingPhotoCount > 0 || photos.contains { if case .local = $0 { true } else { false } }
        }

        var hasInput: Bool {
            var current = inputs
            if mode == .create {
                current.photoIDs = initialInputs.photoIDs
            }
            return current != initialInputs
        }
        
        private var inputs: Inputs {
            Inputs(
                photoIDs: photos.map(\.id),
                beachID: beach?.id,
                period: period,
                maxDepthText: InputText.trimmed(maxDepthText),
                trash: trash,
                totalWeightText: InputText.trimmed(totalWeightText),
                memo: InputText.trimmed(memo)
            )
        }
    }
    
    // MARK: - Mode
    
    enum Mode: Equatable {
        case create
        case edit(recordID: UUID)
    }
    
    struct Inputs: Equatable {
        var photoIDs: [RecordPhoto.ID] = []
        var beachID: UUID?
        var period = ActivityPeriod()
        var maxDepthText = ""
        var trash = TrashSelection()
        var totalWeightText = ""
        var memo = ""
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
            case exitTapped
        }
    }

    // MARK: - Action

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case closeTapped
        case cameraTapped
        case photoDeleteTapped(RecordPhoto.ID)
        case photoMoved(RecordPhoto.ID, to: RecordPhoto.ID)
        case locationFieldTapped
        case dateTapped(PeriodField)
        case timeTapped(PeriodField)
        case maxDepthFocusChanged(isFocused: Bool)
        case totalWeightFocusChanged(isFocused: Bool)
        case memoFocusChanged(isFocused: Bool)
        case trashFieldTapped
        case completeTapped
        case submitResponse(Result<UUID, any Error>)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case recordCreated(recordID: UUID, beachName: String?, trash: TrashSelection, weightKg: Double?)
            case recordUpdated(UUID)
            case closed
        }
    }

    static let maxPhotoCount = 5

    // MARK: - Dependency

    @Dependency(\.recordClient) var recordClient
    @Dependency(\.photoLibraryClient) var photoLibraryClient
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
                let limited = DecimalInput.limited(
                    state.maxDepthText,
                    maximumIntegerDigits: DecimalInput.integerDigits(of: WaterDepth.range),
                    locale: locale
                )

                if limited != state.maxDepthText {
                    state.maxDepthError = maxDepthError(for: state.maxDepthText)
                    state.maxDepthText = limited
                } else {
                    state.maxDepthError = isTypingNumber(limited) ? nil : maxDepthError(for: limited)
                }
                return .none
                
            case .binding(\.totalWeightText):
                let limited = DecimalInput.limited(
                    state.totalWeightText,
                    maximumIntegerDigits: DecimalInput.integerDigits(of: CollectedWeight.kilogramsRange),
                    locale: locale
                )
                if limited != state.totalWeightText {
                    state.totalWeightError = totalWeightError(for: state.totalWeightText)
                    state.totalWeightText = limited
                } else {
                    state.totalWeightError = isTypingNumber(limited) ? nil : totalWeightError(for: limited)
                }
                return .none

            case .binding(\.memo):
                state.isMemoOverLimit = state.memo.count > RecordMemo.maximumLength
                if state.isMemoOverLimit {
                    state.memo = String(state.memo.prefix(RecordMemo.maximumLength))
                }
                if !InputText.isBlank(state.memo) {
                    state.isMemoErrorVisible = false
                }
                return .none
                
            case .closeTapped:
                guard state.hasInput else {
                    return .send(.delegate(.closed))
                }
                
                state.destination = .alert(.make(.recordExitConfirm, cancel: .exitTapped))
                return .none
                
            case .cameraTapped:
                guard state.canOpenPhotoPicker else {
                    return .none
                }
                
                let localAssets = state.photos.compactMap { photo -> PhotoAsset? in
                    guard case let .local(asset) = photo else { return nil }
                    return asset
                }
                state.destination = .photoPicker(PhotosPickerFeature.State(
                    recordType: state.recordType,
                    selectedAssets: localAssets,
                    alreadySelectedCount: state.photos.count - localAssets.count
                ))
                return .none
                
            case let .photoDeleteTapped(id):
                state.photos.remove(id: id)
                return .none
                
            case let .photoMoved(sourceID, targetID):
                guard let source = state.photos.index(id: sourceID),
                      let target = state.photos.index(id: targetID),
                      source != target
                else {
                    return .none
                }
                
                state.photos.move(
                    fromOffsets: IndexSet(integer: source),
                    toOffset: target > source ? target + 1 : target
                )
                return .none
                
            case .locationFieldTapped:
                state.destination = .locationPicker(LocationPickerFeature.State())
                return .none
                
            case let .dateTapped(field):
                state.destination = .datePicker(DatePickerFeature.State(
                    field: field,
                    date: state.period[field] ?? now,
                    today: now,
                    allowedRange: state.period.allowedRange(for: field, now: now),
                    calendar: calendar
                ))
                return .none
                
            case let .timeTapped(field):
                state.destination = .timePicker(TimePickerFeature.State(
                    field: field,
                    date: state.period[field] ?? now,
                    allowedRange: state.period.allowedRange(for: field, now: now),
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

            case .memoFocusChanged(isFocused: true):
                return .none

            case .memoFocusChanged(isFocused: false):
                state.isMemoErrorVisible = InputText.isBlank(state.memo)
                return .none
                
            case .trashFieldTapped:
                state.destination = .trashPicker(TrashPickerFeature.State(
                    selection: state.trash
                ))
                return .none
                
            case .completeTapped:
                guard !state.isSubmitting,
                      validate(&state) else { return .none }
                
                guard let record = newRecord(from: state) else { return .none }
                
                state.isSubmitting = true
                return submit(record, photos: Array(state.photos), mode: state.mode)
                
            case let .submitResponse(.success(recordID)):
                state.isSubmitting = false
                
                switch state.mode {
                case .create:
                    return .send(.delegate(.recordCreated(
                        recordID: recordID,
                        beachName: state.beach?.name,
                        trash: state.trash,
                        weightKg: DecimalInput.number(from: state.totalWeightText, locale: locale)
                    )))
                case .edit:
                    return .send(.delegate(.recordUpdated(recordID)))
                }
                
            case let .submitResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isSubmitting = false
                state.destination = .alert(.make(
                    .recordSubmitFailed,
                    confirm: .retrySubmitTapped
                ))
                return .none
                
            // 앨범에서 고른 그대로 바꿔요. 선택을 푼 사진은 빼고, 계속 고른 사진은 자리를 지키고, 새 사진은 뒤에 붙여요.
            case let .destination(.presented(.photoPicker(.delegate(.finished(photos))))):
                let selectedIDs = Set(photos.map { RecordPhoto.local($0).id })
                state.photos.removeAll { photo in
                    guard case .local = photo else { return false }
                    return !selectedIDs.contains(photo.id)
                }
                for photo in photos where state.photos.count < RecordFormFeature.maxPhotoCount {
                    state.photos.updateOrAppend(.local(photo))
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
                state.period[field] = date
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

            case .destination(.presented(.trashPicker(.delegate(.cancelled)))):
                state.destination = nil
                return .none

            case .destination(.presented(.alert(.retrySubmitTapped))):
                return .send(.completeTapped)
                
            case .destination(.presented(.alert(.exitTapped))):
                return .send(.delegate(.closed))
                
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
        state.isMemoErrorVisible = InputText.isBlank(state.memo)

        return canComplete(state)
    }

    private func canComplete(_ state: State) -> Bool {
        guard !state.isSubmitting,
              !state.photos.isEmpty,
              state.beach != nil,
              periodError(for: state.period) == nil,
              maxDepthError(for: state.maxDepthText) == nil,
              !state.trash.isEmpty,
              totalWeightError(for: state.totalWeightText) == nil,
              !InputText.isBlank(state.memo),
              // 500자를 넘겨 잘린 직후에는 안내 문구가 보이는 동안 저장을 막아요
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

    private func isTypingNumber(_ text: String) -> Bool {
        text == "0" || text.hasSuffix(locale.decimalSeparator ?? ".")
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

    private func newRecord(from state: State) -> NewRecord? {
        guard let beach = state.beach,
              let startedAt = state.period.start,
              let endedAt = state.period.end
        else { return nil }
        
        let memo = InputText.trimmed(state.memo)
        let etcMemo = InputText.trimmed(state.trash.etcMemo)
        
        let recordID = switch state.mode {
        case .create: uuid()
        case let .edit(recordID): recordID
        }
        
        return NewRecord(
            id: recordID,
            beachID: beach.id,
            recordType: state.recordType,
            title: "\(beach.name) \(state.recordType.name) 기록",
            startedAt: startedAt,
            endedAt: endedAt,
            weightKg: DecimalInput.number(from: state.totalWeightText, locale: locale),
            depthM: state.recordType == .plobbing
                ? DecimalInput.number(from: state.maxDepthText, locale: locale)
                : nil,
            memo: memo.isEmpty ? nil : memo,
            trash: state.trash.selectedCategories.map { category in
                NewRecord.Trash(
                    category: category,
                    customName: category == .etc ? (etcMemo.isEmpty ? TrashCategory.etc.name : etcMemo) : nil,
                    quantity: state.trash[category]
                )
            }
        )
    }

    private func submit(_ record: NewRecord, photos: [RecordPhoto], mode: Mode) -> Effect<Action> {
        .run { [recordClient, photoLibraryClient] send in
            do {
                var uploads: [RecordPhotoUpload] = []
                for photo in photos {
                    switch photo {
                    case let .local(asset):
                        let data = try await photoLibraryClient.imageData(asset.id)
                        guard let jpeg = ProfileImageCompressor.compressedJPEG(from: data) else {
                            throw NewRecordError.photoUnavailable
                        }
                        uploads.append(.new(jpeg))
                        
                    case let .remote(storageKey, _):
                        uploads.append(.existing(storageKey: storageKey))
                    }
                }
                
                var record = record
                record.photos = uploads
                
                switch mode {
                case .create:
                    try await recordClient.submitRecord(record)
                case .edit:
                    try await recordClient.updateRecord(UpdatedRecord(record))
                }
                await send(.submitResponse(.success(record.id)))
            } catch {
                await send(.submitResponse(.failure(error)))
            }
        }
    }
}

// MARK: - Conformance

extension RecordFormFeature.Destination.State: Equatable {}

// MARK: - Edit

extension RecordFormFeature.State {
    
    init(editing record: RecordDetail) {
        @Shared(.beaches) var beaches
        
        var trash = TrashSelection()
        for item in record.trash {
            let category = TrashCategory(code: item.trashCode) ?? .etc
            trash[category] += item.quantity
            
            if category == .etc, let customName = item.customName, customName != TrashCategory.etc.name {
                trash.etcMemo = customName
            }
        }
        
        self.init(
            recordType: record.recordType,
            mode: .edit(recordID: record.id),
            photos: IdentifiedArray(uniqueElements: record.photos.map {
                RecordPhoto.remote(storageKey: $0.storageKey, url: $0.url)
            }),
            beach: beaches.first { $0.id == record.beachID },
            period: ActivityPeriod(start: record.startedAt, end: record.endedAt),
            maxDepthText: record.depthM.map(DecimalInput.text(from:)) ?? "",
            trash: trash,
            totalWeightText: record.weightKg.map(DecimalInput.text(from:)) ?? "",
            memo: record.memo ?? ""
        )
    }
}
