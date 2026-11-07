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
                    .font(.custom(PretendardWeight.regular.rawValue, fixedSize: 14.scaled))
                    .foregroundStyle(Color(.textSecondary))
                    .frame(width: 44.scaled, height: 44.scaled)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .overlay {
            Text("주운 쓰레기")
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
            .padding(.top, 8.scaled)
            .padding(.bottom, 8.scaled)
    }
}

// MARK: - Category Row

private extension TrashPickerView {
    
    func categoryRow(_ category: TrashCategory) -> some View {
        HStack(spacing: 12.scaled) {
            VStack(alignment: .leading, spacing: 2.scaled) {
                Text(category.name)
                    .font(.custom(PretendardWeight.medium.rawValue, fixedSize: 16.scaled))
                    .foregroundStyle(Color(.textPrimary))
                
                Text(category.examples)
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.textSecondary))
            }
            
            Spacer()
            
            if store.selection[category] > 0 || store.editingCategory == category {
                countStepper(category)
            } else {
                addButton(category)
            }
        }
        .frame(minHeight: 64.scaled)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.currentWarmBorder))
                .frame(height: 1)
        }
    }
    
    func addButton(_ category: TrashCategory) -> some View {
        Button {
            store.send(.plusTapped(category))
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14.scaled, weight: .medium))
                .foregroundStyle(Color(.textTertiary))
                .frame(width: 32.scaled, height: 32.scaled)
                .background(Color(.gray50), in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color(.currentWarmBorder), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name) 추가")
    }
    
    func countStepper(_ category: TrashCategory) -> some View {
        let count = store.selection[category]
        
        return HStack(spacing: 0) {
            stepperButton(systemName: "minus", color: Color(.textSecondary)) {
                store.send(.minusTapped(category))
            }
            .accessibilityLabel("\(category.name) 빼기")
            
            countLabel(category, count: count)
            
            stepperButton(systemName: "plus", color: Color(.green500)) {
                store.send(.plusTapped(category))
            }
            .disabled(count >= TrashSelection.maximumCount)
            .accessibilityLabel("\(category.name) 더하기")
        }
        .frame(height: 36.scaled)
        .background(Color(.gray50), in: Capsule())
    }
    
    func stepperButton(
        systemName: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13.scaled, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36.scaled, height: 36.scaled)
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
                .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 15.scaled))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 48.scaled)
        } else {
            Button {
                store.send(.countTapped(category))
            } label: {
                Text("\(count)")
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 15.scaled))
                    .foregroundStyle(Color(.textPrimary))
                    .frame(width: 48.scaled, height: 36.scaled)
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
            Text("기타 메모 (선택)")
                .plobbyFont(.helper)
                .foregroundStyle(Color(.textSecondary))
            
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
                    prompt: Text("어떤 쓰레기인지 적어주세요")
                        .foregroundStyle(Color(.textTertiary))
                )
                .focused($focusedField, equals: .etcMemo)
                .font(.custom(PretendardWeight.regular.rawValue, fixedSize: 15.scaled))
                .foregroundStyle(Color(.textPrimary))
                
                Text("\(store.selection.etcMemo.count)/\(TrashSelection.etcMemoMaximumLength)")
                    .plobbyFont(.metadata)
                    .foregroundStyle(isOverLimit ? Color(.currentError) : Color(.textSecondary))
            }
            .padding(12.scaled)
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
        .padding(.vertical, 12.scaled)
    }
    
    func etcMemoBorderColor(isFocused: Bool, isOverLimit: Bool) -> Color {
        if isOverLimit {
            return Color(.currentError)
        }
        
        return isFocused ? Color(.green500) : Color(.currentWarmBorder)
    }
}

// MARK: - Footer

private extension TrashPickerView {
    
    var footer: some View {
        VStack(spacing: 12.scaled) {
            HStack {
                Text(store.selection.isEmpty ? "선택한 종류" : "\(store.selection.selectedCategories.count)종류 선택")
                    .plobbyFont(.helper)
                    .foregroundStyle(Color(.textSecondary))
                
                Spacer()
                
                Text(store.selection.isEmpty ? "없음" : "총 \(store.selection.totalCount)개")
                    .font(.custom(PretendardWeight.semiBold.rawValue, fixedSize: 13.scaled))
                    .foregroundStyle(Color(.textPrimary))
            }
            
            Button {
                store.send(.completeTapped)
            } label: {
                Text("완료")
                    .plobbyFont(.cardTitle)
                    .foregroundStyle(store.isCompleteEnabled ? Color(.gray0) : Color(.textDisabled))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54.scaled)
                    .background(
                        store.isCompleteEnabled ? Color(.green500) : Color(.gray50),
                        in: RoundedRectangle(cornerRadius: 8.scaled)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!store.isCompleteEnabled)
        }
        .padding(.horizontal, 20.scaled)
        .padding(.top, 12.scaled)
        .padding(.bottom, 8.scaled)
        .background(Color(.gray0))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.currentWarmBorder))
                .frame(height: 1)
        }
    }
}
