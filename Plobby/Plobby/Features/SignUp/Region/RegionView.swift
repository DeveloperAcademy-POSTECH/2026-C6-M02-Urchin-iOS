//
//  RegionView.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import SwiftUI

import ComposableArchitecture

struct RegionView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<RegionFeature>
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            progressBar
            titleSection
            beachPicker

            Spacer()

            bottomSection
        }
    }
}

// MARK: - Subviews

private extension RegionView {
    
    var progressBar: some View {
        SignUpProgressBar(currentStep: 2, totalSteps: 2)
            .padding(.top, 23.scaled)
            .padding(.bottom, 31.scaled)
            .padding(.horizontal, 20.scaled)
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            Text("관심 해변을 골라 주세요")
                .plobbyFont(.heading)
                .foregroundStyle(Color(.textPrimary))

            Text("최대 3개까지 고르고, 마이페이지에서 바꿀 수 있어요")
                .plobbyFont(.body)
                .foregroundStyle(Color(.textSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20.scaled)
    }
    
    var beachPicker: some View {
        BeachPickerView(store: store.scope(state: \.picker, action: \.picker))
            .padding(.top, 24.scaled)
            .padding(.horizontal, 20.scaled)
    }
}

// MARK: - 하단 (고른 해변, 가입하기)

private extension RegionView {

    var bottomSection: some View {
        VStack(alignment: .leading, spacing: 8.scaled) {
            selectionSection
            nextButton
        }
        .padding(.top, 16.scaled)
        .padding(.horizontal, 20.scaled)
        .padding(.bottom, 14.scaled)
        .background(Color(.backgroundDefault))
    }

    @ViewBuilder
    var selectionSection: some View {
        if store.picker.selectedBeaches.isEmpty {
            infoLabel
        } else {
            VStack(alignment: .leading, spacing: 0) {
                if store.picker.isSelectionFull {
                    selectionLimitLabel
                }

                selectedBeachChips
            }
        }
    }

    var infoLabel: some View {
        Text("해변을 선택하면 가입할 수 있어요")
            .plobbyFont(.helper)
            .foregroundStyle(Color(.textSecondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8.scaled)
    }

    var selectionLimitLabel: some View {
        Text("관심 해변은 \(BeachPickerFeature.maximumCount)개까지만 고를 수 있어요")
            .plobbyFont(.helper)
            .foregroundStyle(Color(.textSecondary))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var selectedBeachChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4.scaled) {
                ForEach(store.picker.selectedBeaches) { beach in
                    selectedBeachChip(beach)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: 44.scaled)
    }

    func selectedBeachChip(_ beach: Beach) -> some View {
        Button {
            store.send(.picker(.beachTapped(beach.id)))
        } label: {
            HStack(spacing: 0) {
                Text(beach.name)
                    .plobbyFont(.label)
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(.system(size: 12.scaled))
                    .frame(width: 28.scaled, height: 32.scaled)
            }
            .foregroundStyle(Color(.textBrand))
            .padding(.leading, 12.scaled)
            .frame(height: 32.scaled)
            .background(Color(.surfaceBrandSubtle), in: Capsule())
            .frame(height: 44.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(beach.name) 선택 해제")
    }
    
    var nextButton: some View {
        PlobbyButton(text: "가입하기") {
            store.send(.nextButtonTapped)
        }
        .disabled(store.picker.selectedBeachIDs.isEmpty)
    }
}
