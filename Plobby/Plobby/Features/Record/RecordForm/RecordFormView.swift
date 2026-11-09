//
//  RecordFormView.swift
//  Plobby
//
//  Created by 더스틴 on 11/3/26.
//

import SwiftUI
import UniformTypeIdentifiers

import ComposableArchitecture

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
            .plobbyBottomSheet(
                item: $store.scope(state: \.destination?.trashPicker, action: \.destination.trashPicker),
                cornerRadius: 20.scaled,
                showsGrabber: true
            ) { store in
                // 키보드가 올라오면 남은 공간만큼 줄어들어요.
                TrashPickerView(store: store)
                    .frame(maxHeight: trashPickerHeight)
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
                VStack(alignment: .leading, spacing: 24.scaled) {
                    photoSection
                    locationSection
                    periodSection

                    if store.recordType == .plobbing {
                        maxDepthSection
                    }

                    trashSection
                    memoSection
                }
                .padding(.horizontal, 20.scaled)
                .padding(.top, 8.scaled)
                .padding(.bottom, 24.scaled)
            }
            .scrollDismissesKeyboard(.interactively)

            completeButton
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
            .plobbyBottomSheet(
                item: $store.scope(state: \.destination?.datePicker, action: \.destination.datePicker),
                cornerRadius: 20.scaled
            ) { store in
                DatePickerView(store: store)
                    .frame(height: DatePickerView.sheetHeight(weekCount: store.weekCount))
            }
            .plobbyBottomSheet(
                item: $store.scope(state: \.destination?.timePicker, action: \.destination.timePicker),
                cornerRadius: 20.scaled
            ) { store in
                TimePickerView(store: store)
                    .frame(height: TimePickerView.sheetHeight)
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
        if oldField == .memo {
            store.send(.memoFocusChanged(isFocused: false))
        }
        if newField == .memo {
            store.send(.memoFocusChanged(isFocused: true))
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
                        .font(.system(size: 16.scaled, weight: .medium))
                        .foregroundStyle(Color(.textPrimary))
                        .frame(width: 44.scaled, height: 44.scaled)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("닫기")

                Spacer()
            }
        }
        .padding(.horizontal, 12.scaled)
        .frame(height: Self.navigationBarHeight)
    }
    
    /// 내비게이션 바 아래부터 화면 끝까지 덮는 높이예요.
    var trashPickerHeight: CGFloat? {
        let height = contentHeight - Self.navigationBarHeight
        return height > 0 ? height : nil
    }
}

// MARK: - 사진

private extension RecordFormView {

    var photoSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("사진 *")

                Text("사진을 \(maxPhotoCount)장까지 추가할 수 있어요")
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
                    .font(.system(size: 20.scaled, weight: .medium))
                    .foregroundStyle(Color(.textTertiary))
                    .frame(width: 24.scaled, height: 24.scaled)

                // 사진을 고르기 전에는 카메라 아이콘만 보여줘요.
                if !store.photos.isEmpty {
                    Text("\(photoCountText)/\(maxPhotoCount)")
                        .foregroundStyle(Color(.gray600))
                        .font(.custom(PretendardWeight.regular.rawValue, fixedSize: 10.scaled))
                }
            }
            .frame(width: 100.scaled, height: 100.scaled)
            .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
        }
        .disabled(store.photos.count >= maxPhotoCount)
        .accessibilityLabel("사진 추가, \(store.photos.count)/\(maxPhotoCount)")
    }

    var photoCountText: Text {
        Text("\(store.photos.count)")
            .foregroundStyle(store.photos.isEmpty ? Color(.gray600) : Color(.green500))
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
                Color(.gray50)
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

// MARK: - 장소

private extension RecordFormView {

    var locationSection: some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            sectionTitle("활동 장소 *")

            Button {
                store.send(.locationFieldTapped)
            } label: {
                HStack(spacing: 8.scaled) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16.scaled, weight: .medium))
                        .foregroundStyle(Color(.textSecondary))
                        .frame(width: 24.scaled, height: 24.scaled)

                    Text(store.beach?.name ?? "장소 선택")
                        .plobbyFont(.body)
                        .foregroundStyle(store.beach == nil ? Color(.textSecondary) : Color(.textPrimary))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14.scaled, weight: .medium))
                        .foregroundStyle(Color(.textPrimary))
                        .frame(width: 24.scaled, height: 24.scaled)
                }
                .padding(.horizontal, 12.scaled)
                .padding(.vertical, 13.scaled)
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

// MARK: - 날짜와 시간

private extension RecordFormView {

    var periodSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            sectionTitle("날짜와 시간 *")

            VStack(spacing: 8.scaled) {
                periodRow(title: "시작", field: .start, date: store.period.start)

                fieldDivider

                periodRow(title: "종료", field: .end, date: store.period.end)
            }
            .padding(.vertical, 4.scaled)

            if let error = store.periodError {
                errorText(error)
            }
        }
    }

    func periodRow(title: String, field: PeriodField, date: Date?) -> some View {
        HStack(spacing: 12.scaled) {
            Text(title)
                .plobbyFont(.body)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8.scaled) {
                periodChip(
                    text: date.map(Self.dateText) ?? "날짜 선택",
                    isPlaceholder: date == nil
                ) {
                    store.send(.dateTapped(field))
                }

                periodChip(
                    text: date.map(Self.timeText) ?? "시간 선택",
                    isPlaceholder: date == nil
                ) {
                    store.send(.timeTapped(field))
                }
            }
            .frame(width: 248.scaled)
        }
        .frame(height: 48.scaled)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8.scaled) {
                optionalTitle("최대 수심")
                    .frame(maxWidth: .infinity, alignment: .leading)

                unitInputBox("예: 8", text: $store.maxDepthText, unit: "m")
                    .focused($focusedField, equals: .maxDepth)
            }
            .padding(.vertical, 8.scaled)

            if let error = store.maxDepthError {
                errorText(error)
            }
        }
    }
}

// MARK: - 수거한 쓰레기

private extension RecordFormView {

    var trashSection: some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            sectionTitle("수거한 쓰레기 *")

            VStack(spacing: 0) {
                trashSelectRow

                fieldDivider

                totalWeightRow
            }

            if let error = store.totalWeightError {
                errorText(error)
                    .padding(.top, -12.scaled)
            }
        }
    }

    var trashSelectRow: some View {
        Button {
            store.send(.trashFieldTapped)
        } label: {
            HStack(spacing: 8.scaled) {
                Text(store.trash.summary ?? "종류와 개수 선택")
                    .plobbyFont(.body)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14.scaled, weight: .medium))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 24.scaled, height: 24.scaled)
            }
            .padding(.vertical, 8.scaled)
            .frame(minHeight: 53.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var totalWeightRow: some View {
        HStack(spacing: 8.scaled) {
            optionalTitle("총무게")
                .frame(maxWidth: .infinity, alignment: .leading)

            unitInputBox("예: 30", text: $store.totalWeightText, unit: "kg")
                .focused($focusedField, equals: .totalWeight)
        }
        .padding(.vertical, 8.scaled)
    }
}

// MARK: - 활동 메모

private extension RecordFormView {

    var memoSection: some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            sectionTitle("활동 메모 *")

            VStack(alignment: .trailing, spacing: 0) {
                TextField(
                    "",
                    text: $store.memo,
                    prompt: Text("활동 중 기억에 남는 점을 적어 주세요")
                        .foregroundStyle(Color(.textSecondary)),
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
            .frame(minHeight: 140.scaled)
            .formFieldBorder(isError: store.isMemoErrorVisible || store.isMemoOverLimit)

            if store.isMemoErrorVisible {
                errorText("활동 메모를 입력해 주세요")
                    .padding(.top, -12.scaled)
            } else if store.isMemoOverLimit {
                errorText("메모를 \(RecordMemo.maximumLength)자 이내로 줄여주세요.")
                    .padding(.top, -12.scaled)
            }
        }
    }
}

// MARK: - 완료

private extension RecordFormView {

    var completeButton: some View {
        let isActive = store.isCompleteEnabled || store.isSubmitting

        return VStack(spacing: 8.scaled) {
            if !isActive {
                Text("필수 항목을 모두 채워 주세요")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }

            saveButton(isActive: isActive)
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 8.scaled)
        .padding(.bottom, 14.scaled)
        .background(Color(.gray0))
    }

    func saveButton(isActive: Bool) -> some View {
        Button {
            store.send(.completeTapped)
        } label: {
            ZStack {
                if store.isSubmitting {
                    ProgressView()
                        .tint(Color(.gray0))
                } else {
                    Text("기록 저장")
                        .plobbyFont(.actionLabel)
                        .foregroundStyle(isActive ? Color(.gray0) : Color(.textDisabled))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54.scaled)
            .background(
                isActive ? Color(.green500) : Color(.gray300),
                in: RoundedRectangle(cornerRadius: 8.scaled)
            )
        }
        .disabled(!store.isCompleteEnabled)
    }
}

// MARK: - Components

private extension RecordFormView {

    func sectionTitle(_ text: String) -> some View {
        requiredTitle(text, typography: .cardTitle)
    }

    func requiredTitle(_ text: String, typography: PlobbyTypography) -> some View {
        let isRequired = text.hasSuffix("*")
        let title = isRequired ? String(text.dropLast()).trimmingCharacters(in: .whitespaces) : text

        return HStack(spacing: 4.scaled) {
            Text(title)
                .plobbyFont(typography)
                .foregroundStyle(Color(.textPrimary))

            if isRequired {
                Text("*")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.currentError))
            }
        }
    }

    /// "최대 수심 (선택)"처럼 선택 항목 표시를 흐리게 붙여요.
    func optionalTitle(_ title: String) -> some View {
        Text("\(title) \(Text("(선택)").foregroundStyle(Color(.textSecondary)))")
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
    }

    var fieldDivider: some View {
        Rectangle()
            .fill(Color(.gray200))
            .frame(height: 1)
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
                prompt: Text(placeholder).foregroundStyle(Color(.textSecondary))
            )
            .keyboardType(.decimalPad)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))

            Text(unit)
                .plobbyFont(.label)
                .foregroundStyle(Color(.textPrimary))
        }
    }

    func unitInputBox(
        _ placeholder: String,
        text: Binding<String>,
        unit: String
    ) -> some View {
        unitTextField(placeholder, text: text, unit: unit)
            .multilineTextAlignment(.trailing)
            .padding(.horizontal, 12.scaled)
            .frame(width: 120.scaled, height: 48.scaled)
            .background(Color(.gray50), in: RoundedRectangle(cornerRadius: 8.scaled))
    }
}

// MARK: - Style

private extension View {

    func formFieldBorder(isError: Bool = false) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 8.scaled)
                .stroke(isError ? Color(.currentError) : Color(.gray200), lineWidth: 1)
        }
    }
}
