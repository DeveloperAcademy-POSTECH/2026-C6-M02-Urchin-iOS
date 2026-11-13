//
//  RecordReportFeature.swift
//  Plobby
//
//  Created by dlsundn on 11/13/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct RecordReportFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        let recordID: UUID
        var selectedReason: ReportReason?
        var detail = ""
        var isReporting = false
        @Presents var alert: AlertState<Action.Alert>?

        var detailCount: Int {
            detail.count
        }

        var hasDetail: Bool {
            !InputText.isBlank(detail)
        }

        /// 사유를 고르거나 기타를 입력하면 신고할 수 있어요. 둘 중 하나만 고를 수 있어요.
        var canReport: Bool {
            (selectedReason != nil || hasDetail) && !isReporting
        }
    }

    // MARK: - Action

    enum Action {
        case backButtonTapped
        case reasonTapped(ReportReason)
        case detailChanged(String)
        case reportButtonTapped
        case reportResponse(Result<Void, any Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert {
            case confirm
        }

        enum Delegate {
            case reported
        }
    }

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.recordClient) var recordClient

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case let .reasonTapped(reason):
                state.detail = ""
                state.selectedReason = state.selectedReason == reason ? nil : reason
                return .none

            case let .detailChanged(detail):
                state.detail = String(detail.prefix(Self.maximumDetailLength))
                if state.hasDetail {
                    state.selectedReason = nil
                }
                return .none

            case .reportButtonTapped:
                guard state.canReport else { return .none }

                state.isReporting = true
                let reason = state.selectedReason ?? .other
                let detail = reason == .other ? InputText.trimmed(state.detail) : nil
                return report(recordID: state.recordID, reason: reason, detail: detail)

            case .reportResponse(.success):
                state.isReporting = false
                state.alert = .make(.recordReported, confirm: .confirm)
                return .none

            case let .reportResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.isReporting = false
                state.alert = .make(.recordReportFailed)
                return .none

            case .alert(.presented(.confirm)):
                return .send(.delegate(.reported))

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Constant

extension RecordReportFeature {

    static let maximumDetailLength = 500
}

// MARK: - Functions

extension RecordReportFeature {

    private func report(recordID: UUID, reason: ReportReason, detail: String?) -> Effect<Action> {
        .run { send in
            await send(.reportResponse(Result {
                try await recordClient.reportRecord(recordID, reason, detail)
            }))
        }
    }
}
