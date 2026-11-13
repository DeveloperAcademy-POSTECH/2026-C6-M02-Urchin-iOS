//
//  FavoriteBeachAddView.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import SwiftUI

import ComposableArchitecture

struct FavoriteBeachAddView: View {

    // MARK: - Properties

    let store: StoreOf<FavoriteBeachAddFeature>

    static let sheetHeight: CGFloat = 709.scaled

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                header

                BeachPickerView(store: store.scope(state: \.picker, action: \.picker), regionSectionHeight: nil)
                    .padding(.top, 40.scaled)
                    .padding(.bottom, 16.scaled)
            }
            .padding(.horizontal, 20.scaled)

            BeachPickerBottomBar(
                store: store.scope(state: \.picker, action: \.picker),
                emptyMessage: "해변을 선택하면 관심 해변에 추가돼요",
                buttonTitle: "완료"
            ) {
                store.send(.closeButtonTapped)
            }
        }
        .padding(.top, 24.scaled)
        .frame(maxHeight: .infinity, alignment: .top)
        .plobbyToast(store.toast.toastType)
    }
}

// MARK: - Header

extension FavoriteBeachAddView {

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("관심 해변 추가")
                .plobbyFont(.headingLarge)
                .foregroundStyle(Color(.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)

            closeButton
        }
    }

    private var closeButton: some View {
        Button {
            store.send(.closeButtonTapped)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12.scaled, weight: .medium))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: 36.scaled, height: 36.scaled)
                .background(Color(.gray50), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("닫기")
    }
}
