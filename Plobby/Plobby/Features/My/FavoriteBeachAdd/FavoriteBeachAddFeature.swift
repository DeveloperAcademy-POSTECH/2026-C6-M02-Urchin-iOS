//
//  FavoriteBeachAddFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import Foundation

import ComposableArchitecture

/// 마이의 ⊕ 버튼으로 여는 관심 해변 추가 시트예요. 해변을 누를 때마다 바로 추가하거나 해제해요.
@Reducer
struct FavoriteBeachAddFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.favoriteBeaches) var favoriteBeaches
        var picker = BeachPickerFeature.State()
        var toast = ToastFeature.State()

        init() {
            picker.selectedBeachIDs = favoriteBeaches.map(\.id)
        }
    }

    // MARK: - Action

    enum Action {
        case closeButtonTapped
        case favoriteBeachRequestFailed(Beach, isFavorite: Bool)
        case picker(BeachPickerFeature.Action)
        case toast(ToastFeature.Action)
    }

    // MARK: - Dependency

    @Dependency(\.beachClient) var beachClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Scope(state: \.picker, action: \.picker) {
            BeachPickerFeature()
        }

        Scope(state: \.toast, action: \.toast) {
            ToastFeature()
        }

        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .run { _ in await dismiss() }

            // 선택은 BeachPicker가 먼저 바꿔 두고, 여기서 관심 해변과 달라진 만큼 서버에 반영해요
            case let .picker(.beachTapped(beachID)):
                let isSelected = state.picker.selectedBeachIDs.contains(beachID)
                let isFavorite = state.favoriteBeaches.contains { $0.id == beachID }

                guard isSelected != isFavorite else {
                    return state.picker.isSelectionFull && !isSelected
                        ? .send(.toast(.show(.favoriteBeachLimitReached)))
                        : .none
                }
                guard let beach = state.picker.allBeaches.first(where: { $0.id == beachID }) else { return .none }

                state.$favoriteBeaches.withLock {
                    if isSelected {
                        $0.append(beach)
                    } else {
                        $0.removeAll { $0.id == beachID }
                    }
                }
                return requestFavoriteBeach(beach, isFavorite: isSelected)

            case let .favoriteBeachRequestFailed(beach, isFavorite):
                FavoriteBeachToggle.revert(beach, isFavorite: isFavorite, in: state.$favoriteBeaches)
                state.picker.selectedBeachIDs = state.favoriteBeaches.map(\.id)
                return .send(.toast(.show(isFavorite ? .favoriteBeachAddFailed : .favoriteBeachRemoveFailed)))

            case .picker, .toast:
                return .none
            }
        }
    }
}

// MARK: - Functions

extension FavoriteBeachAddFeature {

    private func requestFavoriteBeach(_ beach: Beach, isFavorite: Bool) -> Effect<Action> {
        .run { send in
            do {
                try await FavoriteBeachToggle.request(beach, isFavorite: isFavorite, beachClient: beachClient)
            } catch {
                PlobbyLogger.error(error)
                await send(.favoriteBeachRequestFailed(beach, isFavorite: isFavorite))
            }
        }
    }
}
