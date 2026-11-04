//
//  RecordFormView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI
import UniformTypeIdentifiers

import ComposableArchitecture

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct RecordFormView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<RecordFormFeature>
    
    @FocusState private var focusedField: FocusField?

    private let maxPhotoCount = RecordFormFeature.maxPhotoCount

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    photoSection
                    locationSection
                    periodSection

                    if store.recordType == .plobbing {
                        maxDepthSection
                    }

                    trashSection
                    memoSection
                    completeButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: focusedField) { oldField, newField in
            sendFocusChanged(from: oldField, to: newField)
        }
        .sheet(
            item: $store.scope(state: \.destination?.photoPicker, action: \.destination.photoPicker)
        ) { store in
            PhotosPickerView(store: store)
        }
        // TODO: 장소·날짜·시간·쓰레기 선택 뷰 구현 후 sheet 연결
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

// MARK: - Focus

private extension RecordFormView {

    enum FocusField: Hashable {
        case maxDepth
        case totalWeight
        case memo
    }

    func sendFocusChanged(from oldField: FocusField?, to newField: FocusField?) {
        if oldField == .maxDepth {
            store.send(.maxDepthFocusChanged(isFocused: false))
        }
        if oldField == .totalWeight {
            store.send(.totalWeightFocusChanged(isFocused: false))
        }
        if newField == .maxDepth {
            store.send(.maxDepthFocusChanged(isFocused: true))
        }
        if newField == .totalWeight {
            store.send(.totalWeightFocusChanged(isFocused: true))
        }
    }
}

// MARK: - Navigation Bar

private extension RecordFormView {

    var navigationBar: some View {
        ZStack {
            Text(store.recordType.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)

            HStack {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.formPrimaryText)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("닫기")

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }
}

// MARK: - 활동 사진

private extension RecordFormView {

    var photoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("활동 사진")

                Text("사진을 최대 \(maxPhotoCount)장까지 올릴 수 있어요")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.formSecondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    cameraButton

                    ForEach(Array(store.photos.enumerated()), id: \.element.id) { index, photo in
                        photoThumbnail(photo, isRepresentative: index == 0)
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    var cameraButton: some View {
        Button {
            store.send(.cameraTapped)
        } label: {
            VStack(spacing: 0) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.formPlaceholderText)
                    .frame(width: 20, height: 20)

                (
                    Text("\(store.photos.count)/\(maxPhotoCount)")
                        .foregroundStyle(store.photos.isEmpty ? Color.formPlaceholderText : Color.formAccent)
                )
                .font(.system(size: 10, weight: .medium))
            }
            .frame(width: 100, height: 100)
            .background(Color.formFieldBackground, in: RoundedRectangle(cornerRadius: 8))
        }
        .disabled(store.photos.count >= maxPhotoCount)
        .accessibilityLabel("사진 추가, \(store.photos.count)/\(maxPhotoCount)")
    }

    func photoThumbnail(_ photo: PhotoAsset, isRepresentative: Bool) -> some View {
        PhotoThumbnailView(assetID: photo.id, size: CGSize(width: 100, height: 100))
            .overlay(alignment: .bottom) {
                representativeLabel(isRepresentative: isRepresentative)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                photoDeleteButton(photo.id)
            }
            .onDrag {
                NSItemProvider(object: photo.id as NSString)
            }
            .onDrop(of: [.text], delegate: PhotoDropDelegate { sourceID in
                store.send(.photoMoved(sourceID, to: photo.id), animation: .default)
            })
    }

    @ViewBuilder
    func representativeLabel(isRepresentative: Bool) -> some View {
        if isRepresentative {
            Text("대표사진")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .background(Color.black)
        }
    }

    var photoCornerInset: CGFloat {
        8 * (1 - 1 / 2.squareRoot())
    }

    func photoDeleteButton(_ photoID: PhotoAsset.ID) -> some View {
        Button {
            store.send(.photoDeleteTapped(photoID), animation: .default)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(Color.black, in: Circle())
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .alignmentGuide(.top) { $0[VerticalAlignment.center] - photoCornerInset }
        .alignmentGuide(.trailing) { $0[HorizontalAlignment.center] + photoCornerInset }
        .accessibilityLabel("사진 삭제")
    }
}

// MARK: - Photo Drop Delegate

private struct PhotoDropDelegate: DropDelegate {

    let onDrop: @MainActor @Sendable (PhotoAsset.ID) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else {
            return false
        }

        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let sourceID = object as? String else { return }
            Task { @MainActor in
                onDrop(sourceID)
            }
        }
        return true
    }
}

// MARK: - 활동 장소

private extension RecordFormView {

    var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("활동 장소 *")

            Button {
                store.send(.locationFieldTapped)
            } label: {
                HStack(spacing: 8) {
                    Text(store.beach?.name ?? "활동한 해변을 선택해주세요")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(store.beach == nil ? Color.formPlaceholderText : Color.formPrimaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.formPrimaryText)
                        .frame(width: 20, height: 20)
                }
                .padding(12)
                .contentShape(Rectangle())
                .formFieldBorder(isError: store.isLocationErrorVisible)
            }
            .buttonStyle(.plain)

            if store.isLocationErrorVisible {
                errorText("활동한 해변을 선택해주세요.")
                    .padding(.top, -8)
            }
        }
    }
}

// MARK: - 활동 날짜와 시간

private extension RecordFormView {

    var periodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("활동 날짜와 시간 *")

            VStack(spacing: 0) {
                periodRow(title: "시작", field: .start, date: store.period.start)
                    .padding(12)

                Rectangle()
                    .fill(Color.formBorder)
                    .frame(height: 1)

                periodRow(title: "종료", field: .end, date: store.period.end)
                    .padding(12)
            }
            .formFieldBorder(isError: store.periodError != nil)

            if let error = store.periodError {
                errorText(error)
                    .padding(.top, -8)
            }
        }
    }

    func periodRow(title: String, field: PeriodField, date: Date?) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.formSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                periodChip(
                    text: date.map(Self.dateText) ?? "날짜 선택",
                    isPlaceholder: date == nil
                ) {
                    store.send(.dateTapped(field))
                }
                .frame(width: 144)

                periodChip(
                    text: date.map(Self.timeText) ?? "시간 선택",
                    isPlaceholder: date == nil
                ) {
                    store.send(.timeTapped(field))
                }
                .frame(width: 108)
            }
        }
    }

    func periodChip(text: String, isPlaceholder: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isPlaceholder ? Color.formPlaceholderText : Color.formPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.formFieldBackground, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    nonisolated static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .year().month(.defaultDigits).day()
                .locale(Locale(identifier: "ko_KR"))
        ) + " (\(date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "ko_KR")))))"
    }

    nonisolated static func timeText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .hour().minute()
                .locale(Locale(identifier: "ko_KR"))
        )
    }
}

// MARK: - 최대 수심 (플로빙)

private extension RecordFormView {

    var maxDepthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("최대 수심")

            VStack(alignment: .leading, spacing: 8) {
                unitTextField("0.0", text: $store.maxDepthText, unit: "m")
                    .focused($focusedField, equals: .maxDepth)
                    .padding(12)
                .formFieldBorder(isError: store.maxDepthError != nil)

                if let error = store.maxDepthError {
                    errorText(error)
                } else {
                    Text("활동 중 가장 깊이 내려간 수심을 입력해주세요.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.formSecondaryText)
                }
            }
        }
    }
}

// MARK: - 주운 쓰레기

private extension RecordFormView {

    var trashSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("주운 쓰레기")

            VStack(spacing: 0) {
                Button {
                    store.send(.trashFieldTapped)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldCaption("종류와 개수 (선택)")

                        Text(store.trash.summary ?? "주운 쓰레기를 선택해주세요")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(store.trash.summary == nil ? Color.formPlaceholderText : Color.formPrimaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.formBorder)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 4) {
                    fieldCaption("총무게 (선택)")

                    unitTextField("0", text: $store.totalWeightText, unit: "kg")
                        .focused($focusedField, equals: .totalWeight)
                }
                .padding(12)
            }
            .formFieldBorder(isError: store.totalWeightError != nil)

            if let error = store.totalWeightError {
                errorText(error)
                    .padding(.top, -8)
            }
        }
    }
}

// MARK: - 활동 메모

private extension RecordFormView {

    var memoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("활동 메모")

            VStack(alignment: .trailing, spacing: 0) {
                TextField(
                    "",
                    text: $store.memo,
                    prompt: Text("활동하며 느낀 점을 자유롭게 남겨주세요")
                        .foregroundStyle(Color.formPlaceholderText),
                    axis: .vertical
                )
                .focused($focusedField, equals: .memo)
                .font(.system(size: 16))
                .foregroundStyle(Color.formPrimaryText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("\(store.memo.count)/\(RecordMemo.maximumLength)")
                    .font(.system(size: 13))
                    .foregroundStyle(store.isMemoOverLimit ? Color.formError : Color.formSecondaryText)
            }
            .padding(12)
            .frame(minHeight: 144)
            .formFieldBorder(isError: store.isMemoOverLimit)

            if store.isMemoOverLimit {
                errorText("메모를 \(RecordMemo.maximumLength)자 이내로 줄여주세요.")
                    .padding(.top, -8)
            }
        }
    }
}

// MARK: - 완료

private extension RecordFormView {

    var completeButton: some View {
        let isActive = store.isCompleteEnabled || store.isSubmitting

        return Button {
            store.send(.completeTapped)
        } label: {
            ZStack {
                if store.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("완료")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isActive ? Color.white : Color.formDisabledText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isActive ? Color.formAccent : Color.formFieldBackground,
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .disabled(!store.isCompleteEnabled)
    }
}

// MARK: - Components

private extension RecordFormView {

    func sectionTitle(_ text: String) -> some View {
        let isRequired = text.hasSuffix("*")
        let title = isRequired ? String(text.dropLast()) : text

        return HStack(spacing: 0) {
            Text(title)
            requiredFieldLabel(isRequired: isRequired)
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(Color.formPrimaryText)
    }

    func requiredFieldLabel(isRequired: Bool) -> some View {
        isRequired ? Text("*").foregroundStyle(.red) : Text("")
    }

    func fieldCaption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color.formPlaceholderText)
    }

    func errorText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color.formError)
    }

    func unitTextField(
        _ placeholder: String,
        text: Binding<String>,
        unit: String
    ) -> some View {
        HStack(spacing: 8) {
            TextField(
                "",
                text: text,
                prompt: Text(placeholder).foregroundStyle(Color.formPlaceholderText)
            )
            .keyboardType(.decimalPad)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.formPrimaryText)

            Text(unit)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.formSecondaryText)
        }
    }
}

// MARK: - Style

private extension View {

    func formFieldBorder(isError: Bool = false) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isError ? Color.formError : Color.formBorder, lineWidth: 1)
        }
    }
}

extension Color {

    static let formPrimaryText = Color(red: 0x25 / 255, green: 0x27 / 255, blue: 0x29 / 255)
    static let formSecondaryText = Color(red: 0x6B / 255, green: 0x72 / 255, blue: 0x80 / 255)
    static let formPlaceholderText = Color(red: 0x8F / 255, green: 0x93 / 255, blue: 0x98 / 255)
    static let formBorder = Color(red: 0xE7 / 255, green: 0xE7 / 255, blue: 0xE4 / 255)
    static let formFieldBackground = Color(red: 0xF8 / 255, green: 0xF9 / 255, blue: 0xFA / 255)
    static let formAccent = Color(red: 0x13 / 255, green: 0xBD / 255, blue: 0x7E / 255)
    static let formDisabledText = Color(red: 0xB5 / 255, green: 0xB9 / 255, blue: 0xBD / 255)
    static let formError = Color(red: 0xD9 / 255, green: 0x2D / 255, blue: 0x20 / 255)
}
