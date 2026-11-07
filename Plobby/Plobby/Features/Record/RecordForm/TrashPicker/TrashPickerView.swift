//
//  TrashPickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import SwiftUI

import ComposableArchitecture

// TODO: 추후 디자인 시스템에 맞게 색상과 폰트를 수정
struct TrashPickerView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<TrashPickerFeature>
    
    @FocusState private var focusedField: FocusField?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            header
            guideText
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(TrashCategory.allCases, id: \.self) { category in
                        categoryRow(category)
                        
                        if category == .etc, store.isEtcMemoVisible {
                            etcMemoField
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .background(Color.white)
        .contentShape(Rectangle())
        .onChange(of: store.editingCategory) { _, category in
            if let category {
                focusedField = .count(category)
            } else if case .count = focusedField {
                focusedField = nil
            }
        }
        .onTapGesture {
            if store.editingCategory != nil {
                store.send(.countEditingEnded)
            }
            focusedField = nil
        }
    }
}

// MARK: - Focus

private extension TrashPickerView {
    
    enum FocusField: Hashable {
        case count(TrashCategory)
        case etcMemo
    }
}

// MARK: - Header

private extension TrashPickerView {
    
    var header: some View {
        HStack(spacing: 0) {
            Button {
                store.send(.cancelTapped)
            } label: {
                Text("취소")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.formSecondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .overlay {
            Text("주운 쓰레기")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
    
    var guideText: some View {
        Text(store.guideText)
            .font(.system(size: 13))
            .foregroundStyle(Color.formSecondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
    }
}

// MARK: - Category Row

private extension TrashPickerView {
    
    func categoryRow(_ category: TrashCategory) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.formPrimaryText)
                
                Text(category.examples)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.formSecondaryText)
            }
            
            Spacer()
            
            if store.selection[category] > 0 || store.editingCategory == category {
                countStepper(category)
            } else {
                addButton(category)
            }
        }
        .frame(minHeight: 64)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.formBorder)
                .frame(height: 1)
        }
    }
    
    func addButton(_ category: TrashCategory) -> some View {
        Button {
            store.send(.plusTapped(category))
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.formPlaceholderText)
                .frame(width: 32, height: 32)
                .background(Color.formFieldBackground, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.formBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name) 추가")
    }
    
    func countStepper(_ category: TrashCategory) -> some View {
        let count = store.selection[category]
        
        return HStack(spacing: 0) {
            stepperButton(systemName: "minus", color: Color.formSecondaryText) {
                store.send(.minusTapped(category))
            }
            .accessibilityLabel("\(category.name) 빼기")
            
            countLabel(category, count: count)
            
            stepperButton(systemName: "plus", color: Color.formAccent) {
                store.send(.plusTapped(category))
            }
            .disabled(count >= TrashSelection.maximumCount)
            .accessibilityLabel("\(category.name) 더하기")
        }
        .frame(height: 36)
        .background(Color.formFieldBackground, in: Capsule())
    }
    
    func stepperButton(
        systemName: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func countLabel(_ category: TrashCategory, count: Int) -> some View {
        if store.editingCategory == category {
            TextField("", text: countText(for: category))
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .count(category))
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.formPrimaryText)
                .frame(width: 48)
        } else {
            Button {
                store.send(.countTapped(category))
            } label: {
                Text("\(count)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.formPrimaryText)
                    .frame(width: 48, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(category.name) \(count)개, 눌러서 직접 입력")
        }
    }
    
    func countText(for category: TrashCategory) -> Binding<String> {
        Binding(
            get: { store.countText },
            set: { text in
                guard text != store.countText else { return }
                
                store.send(.countTextChanged(category, text))
            }
        )
    }
}

// MARK: - 기타 메모

private extension TrashPickerView {
    
    var etcMemoField: some View {
        let isFocused = focusedField == .etcMemo
        let isOverLimit = store.isEtcMemoOverLimit
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("기타 메모 (선택)")
                .font(.system(size: 13))
                .foregroundStyle(Color.formSecondaryText)
            
            VStack(alignment: .trailing, spacing: 4) {
                TextField(
                    "",
                    text: Binding(
                        get: { store.selection.etcMemo },
                        set: { memo in
                            guard memo != store.selection.etcMemo else { return }
                            
                            store.send(.etcMemoChanged(memo))
                        }
                    ),
                    prompt: Text("어떤 쓰레기인지 적어주세요")
                        .foregroundStyle(Color.formPlaceholderText)
                )
                .focused($focusedField, equals: .etcMemo)
                .font(.system(size: 15))
                .foregroundStyle(Color.formPrimaryText)
                
                Text("\(store.selection.etcMemo.count)/\(TrashSelection.etcMemoMaximumLength)")
                    .font(.system(size: 12))
                    .foregroundStyle(isOverLimit ? Color.formError : Color.formSecondaryText)
            }
            .padding(12)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(etcMemoBorderColor(isFocused: isFocused, isOverLimit: isOverLimit), lineWidth: 1)
            }
            
            if isOverLimit {
                Text("메모를 \(TrashSelection.etcMemoMaximumLength)자 이내로 줄여주세요.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.formError)
            }
        }
        .padding(.vertical, 12)
    }
    
    func etcMemoBorderColor(isFocused: Bool, isOverLimit: Bool) -> Color {
        if isOverLimit {
            return Color.formError
        }
        
        return isFocused ? Color.formAccent : Color.formBorder
    }
}

// MARK: - Footer

private extension TrashPickerView {
    
    var footer: some View {
        VStack(spacing: 12) {
            HStack {
                Text(store.selection.isEmpty ? "선택한 종류" : "\(store.selection.selectedCategories.count)종류 선택")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.formSecondaryText)
                
                Spacer()
                
                Text(store.selection.isEmpty ? "없음" : "총 \(store.selection.totalCount)개")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.formPrimaryText)
            }
            
            Button {
                store.send(.completeTapped)
            } label: {
                Text("완료")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(store.isCompleteEnabled ? Color.white : Color.formDisabledText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        store.isCompleteEnabled ? Color.formAccent : Color.formFieldBackground,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!store.isCompleteEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.formBorder)
                .frame(height: 1)
        }
    }
}
