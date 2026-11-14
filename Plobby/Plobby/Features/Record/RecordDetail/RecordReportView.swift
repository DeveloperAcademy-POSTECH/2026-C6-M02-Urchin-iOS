//
//  RecordReportView.swift
//  Plobby
//
//  Created by dlsundn on 11/13/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordReportView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<RecordReportFeature>
    @State private var detailText = ""
    @FocusState private var isDetailFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0.scaled) {
            PlobbyNavigationBar(
                title: "신고 사유",
                style: .leading,
                isBackEnabled: !store.isReporting
            ) {
                store.send(.backButtonTapped)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 32.scaled) {
                    reasonSection
                    detailSection
                }
                .padding(.horizontal, 20.scaled)
                .padding(.top, 16.scaled)
                .padding(.bottom, 24.scaled)
            }
            .disabled(store.isReporting)
            .scrollDismissesKeyboard(.interactively)

            reportButton
                .padding(.horizontal, 20.scaled)
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

extension RecordReportView {

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            Text("신고하는 이유를 알려주세요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            VStack(alignment: .leading, spacing: 12.scaled) {
                ForEach(ReportReason.selectableCases, id: \.self) {
                    reasonButton($0)
                }
            }
        }
    }

    private func reasonButton(_ reason: ReportReason) -> some View {
        let isSelected = store.selectedReason == reason

        return Button {
            isDetailFocused = false
            detailText = ""
            store.send(.reasonTapped(reason))
        } label: {
            Text(reason.title)
                .plobbyFont(.labelSelected)
                .foregroundStyle(isSelected ? Color(.currentBrandText) : Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16.scaled)
                .frame(height: 48.scaled)
                .background(
                    isSelected ? Color(.currentBrandSubtle) : Color(.gray0),
                    in: RoundedRectangle(cornerRadius: 8.scaled)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8.scaled)
                        .stroke(isSelected ? Color(.green500) : Color(.gray200), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            sectionTitle("기타")

            VStack(alignment: .trailing, spacing: 8.scaled) {
                TextField("", text: $detailText, axis: .vertical)
                    .onChange(of: detailText) { _, text in
                        let detail = String(text.prefix(RecordReportFeature.maximumDetailLength))

                        detailText = detail
                        store.send(.detailChanged(detail))
                    }
                    .lineLimit(3...)
                    .focused($isDetailFocused)
                    .plobbyFont(.label)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity, minHeight: 72.scaled, alignment: .topLeading)
                    .overlay(alignment: .topLeading) {
                        if detailText.isEmpty {
                            detailPlaceholder
                        }
                    }

                Text("\(store.detailCount)/\(RecordReportFeature.maximumDetailLength)")
                    .plobbyFont(.metadata)
                    .foregroundStyle(Color(.textTertiary))
            }
            .padding(16.scaled)
            .overlay {
                RoundedRectangle(cornerRadius: 8.scaled)
                    .stroke(Color(.gray200), lineWidth: 1)
            }
        }
    }

    private var detailPlaceholder: some View {
        Text("신고 사유를 자세히 알려주세요.\n확인 후 운영 정책에 따라 조치하겠습니다.")
            .plobbyFont(.label)
            .foregroundStyle(Color(.textDisabled))
            .allowsHitTesting(false)
    }

    private var reportButton: some View {
        PlobbyButton(text: "신고하기") {
            isDetailFocused = false
            store.send(.reportButtonTapped)
        }
        .disabled(!store.canReport)
        .padding(.bottom, 8.scaled)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
    }
}
