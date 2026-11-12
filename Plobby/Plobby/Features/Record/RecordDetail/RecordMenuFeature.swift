//
//  RecordMenuFeature.swift
//  Plobby
//
//  Created by 이은지 on 11/13/26.
//

import SwiftUI

import ComposableArchitecture

@Reducer
struct RecordMenuFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let record: RecordSummary
        @Presents var editForm: RecordFormFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    // MARK: - Menu

    enum Menu: Equatable {
        case edit
        case delete
        case report
        case block
    }

    // MARK: - Action

    enum Action {
        case menuSelected(Menu)
        case recordResponse(Result<RecordDetail, any Error>)
        case deleteResponse(Result<Void, any Error>)
        case reportResponse(Result<Void, any Error>)
        case blockResponse(Result<Void, any Error>)
        case editForm(PresentationAction<RecordFormFeature.Action>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case confirmDeleteTapped
            case confirmBlockTapped
            case deletedConfirmTapped
            case reportedConfirmTapped
            case blockedConfirmTapped
        }

        enum Delegate {
            case updated
            case deleted(UUID)
            case reported(UUID)
            case blocked(userID: UUID)
        }
    }

    // MARK: - Dependency

    @Dependency(\.recordClient) var recordClient
    @Dependency(\.userClient) var userClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .menuSelected(.edit):
                return .run { [recordID = state.record.id] send in
                    await send(.recordResponse(Result { try await recordClient.fetchRecord(recordID) }))
                }

            case let .recordResponse(.success(record)):
                state.editForm = RecordFormFeature.State(editing: record)
                return .none

            case let .recordResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.recordLoadFailed)
                return .none

            case .editForm(.presented(.delegate(.recordUpdated))):
                state.editForm = nil
                return .send(.delegate(.updated))

            case .editForm(.presented(.delegate(.closed))):
                state.editForm = nil
                return .none

            case .menuSelected(.delete):
                state.alert = .make(.recordDeleteConfirm, confirm: .confirmDeleteTapped)
                return .none

            case .alert(.presented(.confirmDeleteTapped)):
                return .run { [recordID = state.record.id] send in
                    await send(.deleteResponse(Result { try await recordClient.removeRecord(recordID) }))
                }

            case .deleteResponse(.success):
                state.alert = .make(.recordDeleted, confirm: .deletedConfirmTapped)
                return .none

            case let .deleteResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.recordDeleteFailed)
                return .none

            case .alert(.presented(.deletedConfirmTapped)):
                return .send(.delegate(.deleted(state.record.id)))

            case .menuSelected(.report):
                return .run { [recordID = state.record.id] send in
                    await send(.reportResponse(Result { try await recordClient.reportRecord(recordID) }))
                }

            case .reportResponse(.success):
                state.alert = .make(.recordReported, confirm: .reportedConfirmTapped)
                return .none

            case let .reportResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.recordReportFailed)
                return .none

            case .alert(.presented(.reportedConfirmTapped)):
                return .send(.delegate(.reported(state.record.id)))

            case .menuSelected(.block):
                state.alert = .make(.userBlockConfirm, confirm: .confirmBlockTapped)
                return .none

            case .alert(.presented(.confirmBlockTapped)):
                return .run { [userID = state.record.userID] send in
                    await send(.blockResponse(Result { try await userClient.submitBlock(userID) }))
                }

            case .blockResponse(.success):
                state.alert = .make(.userBlocked, confirm: .blockedConfirmTapped)
                return .none

            case let .blockResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.alert = .make(.userBlockFailed)
                return .none

            case .alert(.presented(.blockedConfirmTapped)):
                return .send(.delegate(.blocked(userID: state.record.userID)))

            case .editForm, .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$editForm, action: \.editForm) {
            RecordFormFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Menu Items

extension RecordMenuFeature.Menu {

    static func menus(isMine: Bool) -> [Self] {
        isMine ? [.edit, .delete] : [.report, .block]
    }

    func item(_ action: @escaping () -> Void) -> PlobbyDropdownMenu.Item {
        switch self {
        case .edit: .edit(action)
        case .delete: .delete(action)
        case .report: .report(action)
        case .block: .block(action)
        }
    }
}

// MARK: - View

extension View {

    func recordMoreMenu(
        record menuRecord: Binding<RecordSummary?>,
        isMine: @escaping (RecordSummary) -> Bool,
        onSelect: @escaping (RecordSummary, RecordMenuFeature.Menu) -> Void
    ) -> some View {
        let items = menuRecord.wrappedValue.map { record in
            RecordMenuFeature.Menu.menus(isMine: isMine(record)).map { menu in
                menu.item { onSelect(record, menu) }
            }
        } ?? []

        return plobbyAnchoredDropdownMenu(
            isPresented: Binding(
                get: { menuRecord.wrappedValue != nil },
                set: { if !$0 { menuRecord.wrappedValue = nil } }
            ),
            items: items
        )
    }

    func recordMenu(store: StoreOf<RecordMenuFeature>?) -> some View {
        overlay {
            if let store {
                RecordMenuPresenter(store: store)
            }
        }
    }
}

private struct RecordMenuPresenter: View {

    @Bindable var store: StoreOf<RecordMenuFeature>

    var body: some View {
        Color.clear
            .plobbyAlert(store: store, state: \.alert, action: \.alert)
            .fullScreenCover(item: $store.scope(state: \.editForm, action: \.editForm)) { store in
                RecordFormView(store: store)
            }
    }
}
