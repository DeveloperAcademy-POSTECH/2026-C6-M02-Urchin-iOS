//
//  WithdrawalView.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import SwiftUI

import ComposableArchitecture

struct WithdrawalView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<WithdrawalFeature>
    @State private var detailText = ""
    @FocusState private var isDetailFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlobbyNavigationBar(
                title: "plobby 탈퇴",
                style: .leading,
                isBackEnabled: !store.isWithdrawing
            ) {
                store.send(.backButtonTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    reasonSection
                    detailSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            withdrawButton
                .padding(.horizontal, 20)
        }
        .background(Color(.gray0))
        .contentShape(Rectangle())
        .onTapGesture {
            isDetailFocused = false
        }
        .toolbar(.hidden, for: .navigationBar)
        .plobbyAlert(store: store, state: \.alert, action: \.alert)
    }
}

// MARK: - Subviews

extension WithdrawalView {

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("어떤 점이 가장 아쉬우셨나요?")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(WithdrawalReason.allCases, id: \.self) {
                    reasonButton($0)
                }
            }
        }
    }

    private func reasonButton(_ reason: WithdrawalReason) -> some View {
        let isSelected = store.selectedReason == reason

        return Button {
            store.send(.reasonTapped(reason))
        } label: {
            Text(reason.title)
                .plobbyFont(.labelSelected)
                .foregroundStyle(isSelected ? Color(.currentBrandText) : Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(
                    isSelected ? Color(.currentBrandSubtle) : Color(.gray0),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(.green500) : Color(.gray200), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("기타")

            VStack(alignment: .trailing, spacing: 8) {
                TextField("", text: $detailText, axis: .vertical)
                    .onChange(of: detailText) { _, text in
                        let detail = String(text.prefix(WithdrawalFeature.maximumDetailLength))

                        detailText = detail
                        store.send(.detailChanged(detail))
                    }
                    .onChange(of: store.detail) { _, detail in
                        guard detailText != detail else { return }
                        detailText = detail
                    }
                    .lineLimit(3...)
                    .focused($isDetailFocused)
                    .plobbyFont(.label)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                        if detailText.isEmpty {
                            detailPlaceholder
                        }
                    }

                Text("\(store.detailCount)/\(WithdrawalFeature.maximumDetailLength)")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.textTertiary))
            }
            .padding(16)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.gray200), lineWidth: 1)
            }
        }
    }

    private var detailPlaceholder: some View {
        Text("아쉬웠던 점을 자유롭게 남겨주세요.\n남겨주신 의견을 참고해서 더 나은 plobby를 만들게요.")
            .plobbyFont(.label)
            .foregroundStyle(Color(.textDisabled))
            .allowsHitTesting(false)
    }

    private var withdrawButton: some View {
        PlobbyButton(text: "탈퇴하기") {
            store.send(.withdrawButtonTapped)
        }
        .disabled(!store.canWithdraw)
        .padding(.bottom, 8)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
    }
}
