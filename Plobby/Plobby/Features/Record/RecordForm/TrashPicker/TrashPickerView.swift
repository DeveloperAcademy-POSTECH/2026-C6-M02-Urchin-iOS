//
//  TrashPickerView.swift
//  Plobby
//
//  Created by 더스틴 on 11/5/26.
//

import SwiftUI

import ComposableArchitecture

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
                .padding(.horizontal, 20.scaled)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .background(Color(.gray0))
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
                    .plobbyFont(.label)
                    .foregroundStyle(Color(.textSecondary))
                    .frame(width: 44.scaled, height: 44.scaled)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .overlay {
            Text("수거한 쓰레기")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))
        }
        .frame(height: 56.scaled)
        .padding(.horizontal, 20.scaled)
        .padding(.top, 24.scaled)
    }
    
    var guideText: some View {
        Text(store.guideText)
            .plobbyFont(.helper)
            .foregroundStyle(Color(.textSecondary))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20.scaled)
            .padding(.top, 24.scaled)
            .padding(.bottom, 12.scaled)
    }
}

// MARK: - Category Row

private extension TrashPickerView {
    
    func categoryRow(_ category: TrashCategory) -> some View {
        HStack(spacing: 12.scaled) {
            VStack(alignment: .leading, spacing: 4.scaled) {
                Text(category.name)
                    .plobbyFont(.cardTitle)
                    .foregroundStyle(Color(.textPrimary))
                
                Text(category.examples)
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
            }
            
            Spacer()
            
            if store.selection[category] > 0 || store.editingCategory == category {
                countStepper(category)
            } else {
                addButton(category)
            }
        }
        .frame(minHeight: 72.scaled)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.gray200))
                .frame(height: 1)
        }
    }
    
    func addButton(_ category: TrashCategory) -> some View {
        Button {
            store.send(.plusTapped(category))
        } label: {
            Image(.trashAdd)
                .resizable()
                .frame(width: 44.scaled, height: 44.scaled)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name) 추가")
    }
    
    func countStepper(_ category: TrashCategory) -> some View {
        let count = store.selection[category]
        
        return HStack(spacing: 4.scaled) {
            stepperButton(.stepperMinus) {
                store.send(.minusTapped(category))
            }
            .accessibilityLabel("\(category.name) 빼기")
            
            countLabel(category, count: count)
            
            stepperButton(.stepperPlus) {
                store.send(.plusTapped(category))
            }
            .disabled(count >= TrashSelection.maximumCount)
            .opacity(count >= TrashSelection.maximumCount ? 0.3 : 1)
            .accessibilityLabel("\(category.name) 더하기")
        }
        .frame(height: 44.scaled)
        .background(Color(.gray0), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.green500), lineWidth: 1)
        }
    }
    
    func stepperButton(
        _ image: ImageResource,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .frame(width: 20.scaled, height: 20.scaled)
                .frame(width: 44.scaled, height: 44.scaled)
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
                .plobbyFont(.actionLabel)
                .foregroundStyle(Color(.textPrimary))
                .tint(Color(.green500))
                .frame(width: 52.scaled)
        } else {
            Button {
                store.send(.countTapped(category))
            } label: {
                Text("\(count)")
                    .plobbyFont(.actionLabel)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 52.scaled, height: 44.scaled)
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
        
        return VStack(alignment: .leading, spacing: 8.scaled) {
            Text("기타 메모")
                .plobbyFont(.label)
                .foregroundStyle(Color(.textPrimary))
            
            VStack(alignment: .trailing, spacing: 4.scaled) {
                TextField(
                    "",
                    text: Binding(
                        get: { store.selection.etcMemo },
                        set: { memo in
                            guard memo != store.selection.etcMemo else { return }
                            
                            store.send(.etcMemoChanged(memo))
                        }
                    ),
                    prompt: Text("어떤 쓰레기를 수거했는지 적어 주세요")
                        .foregroundStyle(Color(.textTertiary))
                )
                .focused($focusedField, equals: .etcMemo)
                .plobbyFont(.body)
                .foregroundStyle(Color(.textPrimary))
                
                Text("\(store.selection.etcMemo.count)/\(TrashSelection.etcMemoMaximumLength)")
                    .plobbyFont(.helper)
                    .foregroundStyle(isOverLimit ? Color(.currentError) : Color(.textSecondary))
            }
            .padding(12.scaled)
            .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 8.scaled))
            .overlay {
                RoundedRectangle(cornerRadius: 8.scaled)
                    .stroke(etcMemoBorderColor(isFocused: isFocused, isOverLimit: isOverLimit), lineWidth: 1)
            }
            
            if isOverLimit {
                Text("메모를 \(TrashSelection.etcMemoMaximumLength)자 이내로 줄여주세요.")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.currentError))
            }
        }
        .padding(.top, 12.scaled)
        .padding(.bottom, 20.scaled)
    }
    
    func etcMemoBorderColor(isFocused: Bool, isOverLimit: Bool) -> Color {
        if isOverLimit {
            return Color(.currentError)
        }
        
        return isFocused ? Color(.green500) : Color(.gray300)
    }
}

// MARK: - Footer

private extension TrashPickerView {
    
    var footer: some View {
        VStack(spacing: 24.scaled) {
            HStack {
                Text(store.selection.isEmpty ? "선택한 종류" : "\(store.selection.selectedCategories.count)종류 선택")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
                
                Spacer()
                
                Text(store.selection.isEmpty ? "없음" : "총 \(store.selection.totalCount)개")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textPrimary))
            }
            .padding(.vertical, 16.scaled)
            
            PlobbyButton(text: "완료") {
                store.send(.completeTapped)
            }
            .disabled(!store.isCompleteEnabled)
        }
        .padding(.horizontal, 20.scaled)
        // 시안 하단 여백 48에서 홈 인디케이터 영역(34)을 뺀 값
        .padding(.bottom, 14.scaled)
        .background(Color(.gray0))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.gray200))
                .frame(height: 1)
        }
    }
}
