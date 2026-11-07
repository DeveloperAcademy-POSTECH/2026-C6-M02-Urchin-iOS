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
    @State private var contentHeight: CGFloat = 0

    private let maxPhotoCount = RecordFormFeature.maxPhotoCount
    private static let navigationBarHeight: CGFloat = 56.scaled

    // MARK: - Body

    var body: some View {
        formWithPickers
            .fullScreenCover(
                item: $store.scope(state: \.destination?.locationPicker, action: \.destination.locationPicker)
            ) { store in
                LocationPickerView(store: store)
            }
            .sheet(
                item: $store.scope(state: \.destination?.trashPicker, action: \.destination.trashPicker)
            ) { store in
                TrashPickerView(store: store)
                    .presentationDetents(belowNavigationBarDetents)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
            .plobbyAlert($store.scope(state: \.destination?.alert, action: \.destination.alert))
    }
}

// MARK: - Subviews

private extension RecordFormView {

    var formContent: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                VStack(alignment: .leading, spacing: 40.scaled) {
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
                .padding(.horizontal, 20.scaled)
                .padding(.top, 40.scaled)
                .padding(.bottom, 40.scaled)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.gray0))
        .background {
            Color.clear
                .ignoresSafeArea(.keyboard)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: focusedField) { oldField, newField in
            sendFocusChanged(from: oldField, to: newField)
        }
    }

    var formWithPickers: some View {
        formContent
            .sheet(
                item: $store.scope(state: \.destination?.photoPicker, action: \.destination.photoPicker)
            ) { store in
                PhotosPickerView(store: store)
            }
            .sheet(
                item: $store.scope(state: \.destination?.datePicker, action: \.destination.datePicker)
            ) { store in
                DatePickerView(store: store)
                    .presentationDetents([.height(DatePickerView.sheetHeight(weekCount: store.weekCount))])
                    .presentationCornerRadius(20)
            }
            .sheet(
                item: $store.scope(state: \.destination?.timePicker, action: \.destination.timePicker)
            ) { store in
                TimePickerView(store: store)
                    .presentationDetents([.height(TimePickerView.sheetHeight)])
                    .presentationCornerRadius(20)
            }
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
            Text(store.title)
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            HStack {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17.scaled, weight: .medium))
                        .foregroundStyle(Color(.textPrimary))
                        .frame(width: 24.scaled, height: 24.scaled)
                }
                .accessibilityLabel("닫기")

                Spacer()
            }
        }
        .padding(.horizontal, 20.scaled)
        .frame(height: Self.navigationBarHeight)
    }
    
    var belowNavigationBarDetents: Set<PresentationDetent> {
        let height = contentHeight - Self.navigationBarHeight
        guard height > 0 else { return [.large] }
        
        return [.height(height), .large]
    }
}

// MARK: - 활동 사진

private extension RecordFormView {

    var photoSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("활동 사진")

                Text("사진을 최대 \(maxPhotoCount)장까지 올릴 수 있어요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8.scaled) {
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
                    .font(.system(size: 15.scaled))
                    .foregroundStyle(Color(.textTertiary))
                    .frame(width: 20.scaled, height: 20.scaled)

                (
                    Text("\(store.photos.count)/\(maxPhotoCount)")
                        .foregroundStyle(store.photos.isEmpty ? Color(.textTertiary) : Color(.green500))
                )
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 10.scaled))
            }
            .frame(width: 100.scaled, height: 100.scaled)
            .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
        .disabled(store.photos.count >= maxPhotoCount)
        .accessibilityLabel("사진 추가, \(store.photos.count)/\(maxPhotoCount)")
    }

    func photoThumbnail(_ photo: RecordPhoto, isRepresentative: Bool) -> some View {
        photoImage(photo)
            .overlay(alignment: .bottom) {
                representativeLabel(isRepresentative: isRepresentative)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.scaled))
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
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 11.scaled))
                .foregroundStyle(Color(.gray0))
                .frame(maxWidth: .infinity)
                .frame(height: 22.scaled)
                .background(Color(.neutralBlack))
        }
    }

    var photoCornerInset: CGFloat {
        8 * (1 - 1 / 2.squareRoot())
    }

    @ViewBuilder
    func photoImage(_ photo: RecordPhoto) -> some View {
        let size = CGSize(width: 100, height: 100)
        
        switch photo {
        case let .local(asset):
            PhotoThumbnailView(assetID: asset.id, size: size)
            
        case let .remote(_, url):
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(.systemGray6)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }

    func photoDeleteButton(_ photoID: RecordPhoto.ID) -> some View {
        Button {
            store.send(.photoDeleteTapped(photoID), animation: .default)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 7.scaled, weight: .bold))
                .foregroundStyle(Color(.gray0))
                .frame(width: 14.scaled, height: 14.scaled)
                .background(Color(.neutralBlack), in: Circle())
                .frame(width: 32.scaled, height: 32.scaled)
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

    let onDrop: @MainActor @Sendable (RecordPhoto.ID) -> Void

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
        VStack(alignment: .leading, spacing: 16.scaled) {
            sectionTitle("활동 장소 *")

            Button {
                store.send(.locationFieldTapped)
            } label: {
                HStack(spacing: 8.scaled) {
                    Text(store.beach?.name ?? "활동한 해변을 선택해주세요")
                        .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
                        .foregroundStyle(store.beach == nil ? Color(.textTertiary) : Color(.textPrimary))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14.scaled, weight: .medium))
                        .foregroundStyle(Color(.textPrimary))
                        .frame(width: 20.scaled, height: 20.scaled)
                }
                .padding(12.scaled)
                .contentShape(Rectangle())
                .formFieldBorder(isError: store.isLocationErrorVisible)
            }
            .buttonStyle(.plain)

            if store.isLocationErrorVisible {
                errorText("활동한 해변을 선택해주세요.")
                    .padding(.top, -8.scaled)
            }
        }
    }
}

// MARK: - 활동 날짜와 시간

private extension RecordFormView {

    var periodSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            sectionTitle("활동 날짜와 시간 *")

            VStack(spacing: 0) {
                periodRow(title: "시작", field: .start, date: store.period.start)
                    .padding(12.scaled)

                Rectangle()
                    .fill(Color(.currentWarmBorder))
                    .frame(height: 1)

                periodRow(title: "종료", field: .end, date: store.period.end)
                    .padding(12.scaled)
            }
            .formFieldBorder(isError: store.periodError != nil)

            if let error = store.periodError {
                errorText(error)
                    .padding(.top, -8.scaled)
            }
        }
    }

    func periodRow(title: String, field: PeriodField, date: Date?) -> some View {
        HStack(spacing: 12.scaled) {
            Text(title)
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8.scaled) {
                periodChip(
                    text: date.map(Self.dateText) ?? "날짜 선택",
                    isPlaceholder: date == nil
                ) {
                    store.send(.dateTapped(field))
                }
                .frame(width: 144.scaled)

                periodChip(
                    text: date.map(Self.timeText) ?? "시간 선택",
                    isPlaceholder: date == nil
                ) {
                    store.send(.timeTapped(field))
                }
                .frame(width: 108.scaled)
            }
        }
    }

    func periodChip(text: String, isPlaceholder: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .plobbyFont(.label)
                .foregroundStyle(isPlaceholder ? Color(.textTertiary) : Color(.textPrimary))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 48.scaled)
                .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
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
        VStack(alignment: .leading, spacing: 16.scaled) {
            sectionTitle("최대 수심")

            VStack(alignment: .leading, spacing: 8.scaled) {
                unitTextField("0.0", text: $store.maxDepthText, unit: "m")
                    .focused($focusedField, equals: .maxDepth)
                    .padding(12.scaled)
                .formFieldBorder(isError: store.maxDepthError != nil)

                if let error = store.maxDepthError {
                    errorText(error)
                } else {
                    Text("활동 중 가장 깊이 내려간 수심을 입력해주세요.")
                        .plobbyFont(.helper)
                        .foregroundStyle(Color(.textSecondary))
                }
            }
        }
    }
}

// MARK: - 주운 쓰레기

private extension RecordFormView {

    var trashSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            sectionTitle("주운 쓰레기")

            VStack(spacing: 0) {
                Button {
                    store.send(.trashFieldTapped)
                } label: {
                    VStack(alignment: .leading, spacing: 4.scaled) {
                        fieldCaption("종류와 개수 (선택)")

                        Text(store.trash.summary ?? "주운 쓰레기를 선택해주세요")
                            .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
                            .foregroundStyle(store.trash.summary == nil ? Color(.textTertiary) : Color(.textPrimary))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12.scaled)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color(.currentWarmBorder))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 4.scaled) {
                    fieldCaption("총무게 (선택)")

                    unitTextField("0", text: $store.totalWeightText, unit: "kg")
                        .focused($focusedField, equals: .totalWeight)
                }
                .padding(12.scaled)
            }
            .formFieldBorder(isError: store.totalWeightError != nil)

            if let error = store.totalWeightError {
                errorText(error)
                    .padding(.top, -8.scaled)
            }
        }
    }
}

// MARK: - 활동 메모

private extension RecordFormView {

    var memoSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            sectionTitle("활동 메모")

            VStack(alignment: .trailing, spacing: 0) {
                TextField(
                    "",
                    text: $store.memo,
                    prompt: Text("활동하며 느낀 점을 자유롭게 남겨주세요")
                        .foregroundStyle(Color(.textTertiary)),
                    axis: .vertical
                )
                .focused($focusedField, equals: .memo)
                .plobbyFont(.body)
                .foregroundStyle(Color(.textPrimary))
                .lineSpacing(4.scaled)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("\(store.memo.count)/\(RecordMemo.maximumLength)")
                    .plobbyFont(.helper)
                    .foregroundStyle(store.isMemoOverLimit ? Color(.currentError) : Color(.textSecondary))
            }
            .padding(12.scaled)
            .frame(minHeight: 144.scaled)
            .formFieldBorder(isError: store.isMemoOverLimit)

            if store.isMemoOverLimit {
                errorText("메모를 \(RecordMemo.maximumLength)자 이내로 줄여주세요.")
                    .padding(.top, -8.scaled)
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
                        .tint(Color(.gray0))
                } else {
                    Text("완료")
                        .plobbyFont(.cardTitle)
                        .foregroundStyle(isActive ? Color(.gray0) : Color(.textDisabled))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56.scaled)
            .background(
                isActive ? Color(.green500) : Color(.gray50),
                in: RoundedRectangle(cornerRadius: 8.scaled)
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
        .plobbyFont(.cardTitle)
        .foregroundStyle(Color(.textPrimary))
    }

    func requiredFieldLabel(isRequired: Bool) -> some View {
        isRequired ? Text("*").foregroundStyle(Color(.currentError)) : Text("")
    }

    func fieldCaption(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.helper)
            .foregroundStyle(Color(.textTertiary))
    }

    func errorText(_ text: String) -> some View {
        Text(text)
            .plobbyFont(.helper)
            .foregroundStyle(Color(.currentError))
    }

    func unitTextField(
        _ placeholder: String,
        text: Binding<String>,
        unit: String
    ) -> some View {
        HStack(spacing: 8.scaled) {
            TextField(
                "",
                text: text,
                prompt: Text(placeholder).foregroundStyle(Color(.textTertiary))
            )
            .keyboardType(.decimalPad)
            .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
            .foregroundStyle(Color(.textPrimary))

            Text(unit)
                .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
                .foregroundStyle(Color(.textSecondary))
        }
    }
}

// MARK: - Style

private extension View {

    func formFieldBorder(isError: Bool = false) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 8.scaled)
                .stroke(isError ? Color(.currentError) : Color(.currentWarmBorder), lineWidth: 1)
        }
    }
}
