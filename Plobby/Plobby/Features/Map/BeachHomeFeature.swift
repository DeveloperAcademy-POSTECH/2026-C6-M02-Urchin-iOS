//
//  BeachHomeFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/6/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct BeachHomeFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var beach: Beach
        var summary: LoadState<BeachSummary> = .loading
        var filter: RecordFilter = .all
        var records: LoadState<[BeachRecord]> = .loading
        var sortOption: SortOption = .latest
        var visibleRecordCount = BeachHomeFeature.initialRecordCount
        @Shared(.favoriteBeaches) var favoriteBeaches
        @Shared(.membershipStatus) var membershipStatus
        @Presents var alert: AlertState<Action.Alert>?

        init(beach: Beach) {
            self.beach = beach
        }

        var isFavorite: Bool {
            favoriteBeaches.contains { $0.id == beach.id }
        }

        var isMember: Bool {
            if case .member = membershipStatus { true } else { false }
        }

        var sortedRecords: [BeachRecord] {
            guard case let .loaded(records) = records else { return [] }

            switch sortOption {
            case .latest:
                return records
            case .popular:
                return records.sorted { ($0.likeCount, $0.createdAt) > ($1.likeCount, $1.createdAt) }
            }
        }

        var visibleRecords: [BeachRecord] {
            Array(sortedRecords.prefix(visibleRecordCount))
        }

        var hasMoreRecords: Bool {
            sortedRecords.count > visibleRecordCount
        }
    }

    // MARK: - Action

    enum Action {
        case task
        case summaryResponse(Result<BeachSummary, any Error>)
        case recordsResponse(Result<[BeachRecord], any Error>)
        case filterTapped(RecordFilter)
        case favoriteTapped
        case favoriteResponse(Result<Void, any Error>, beach: Beach, isFavorite: Bool)
        case sortOptionChanged(SortOption)
        case moreRecordsTapped
        case showAllTapped
        case recordTapped(BeachRecord)
        /// 신고한 기록을 목록에서 빼요.
        case recordHidden(UUID)
        /// 차단한 사용자의 기록을 목록에서 모두 빼요.
        case userBlocked(UUID)
        case backTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {}

        enum Delegate: Equatable {
            case recordSelected(BeachRecord)
        }
    }

    static let initialRecordCount = 3
    static let moreRecordCount = 10
    static let guardianLimit = 9

    private nonisolated enum CancelID {
        case records
    }

    // MARK: - Dependency

    @Dependency(\.beachClient) var beachClient
    @Dependency(\.dismiss) var dismiss

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.summary = .loading
                state.records = .loading
                return .merge(
                    fetchSummary(beachID: state.beach.id),
                    fetchRecords(beachID: state.beach.id, filter: state.filter)
                )

            case let .summaryResponse(.success(summary)):
                state.summary = .loaded(summary)
                return .none

            case let .summaryResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.summary = .failed
                return .none

            case let .recordsResponse(.success(records)):
                state.records = records.isEmpty ? .empty : .loaded(records)
                return .none

            case let .recordsResponse(.failure(error)):
                PlobbyLogger.error(error)
                state.records = .failed
                return .none

            case let .filterTapped(filter):
                guard filter != state.filter else { return .none }

                state.filter = filter
                state.records = .loading
                state.visibleRecordCount = Self.initialRecordCount
                return fetchRecords(beachID: state.beach.id, filter: filter)

            case .favoriteTapped:
                switch FavoriteBeachToggle.toggle(state.beach, in: state.$favoriteBeaches) {
                case .limitReached:
                    state.alert = .make(.favoriteBeachLimit)
                    return .none

                case let .toggled(isFavorite):
                    return .run { [beach = state.beach] send in
                        await send(.favoriteResponse(
                            Result { try await FavoriteBeachToggle.request(beach, isFavorite: isFavorite, beachClient: beachClient) },
                            beach: beach,
                            isFavorite: isFavorite
                        ))
                    }
                }

            case .favoriteResponse(.success, _, _):
                return .none

            case let .favoriteResponse(.failure(error), beach, isFavorite):
                PlobbyLogger.error(error)
                FavoriteBeachToggle.revert(beach, isFavorite: isFavorite, in: state.$favoriteBeaches)
                return .none

            case let .sortOptionChanged(option):
                state.sortOption = option
                state.visibleRecordCount = Self.initialRecordCount
                return .none

            case .moreRecordsTapped:
                state.visibleRecordCount += Self.moreRecordCount
                return .none

            // TODO: 기획 확정 후 전체보기 동작 구현
            case .showAllTapped:
                return .none

            case let .recordTapped(record):
                return .send(.delegate(.recordSelected(record)))

            // 목록에서 바로 빼고, 요약은 숨긴 기록을 뺀 기준으로 다시 불러와요.
            case let .recordHidden(recordID):
                return removeRecords(where: { $0.id == recordID }, state: &state)

            case let .userBlocked(userID):
                return removeRecords(where: { $0.userID == userID }, state: &state)

            case .backTapped:
                return .run { _ in await dismiss() }

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension BeachHomeFeature {

    private func removeRecords(where shouldRemove: (BeachRecord) -> Bool, state: inout State) -> Effect<Action> {
        if case var .loaded(records) = state.records {
            records.removeAll(where: shouldRemove)
            state.records = records.isEmpty ? .empty : .loaded(records)
        }
        return fetchSummary(beachID: state.beach.id)
    }

    private func fetchSummary(beachID: UUID) -> Effect<Action> {
        .run { send in
            await send(.summaryResponse(Result {
                try await beachClient.fetchBeachRecords(beachID, nil).summary(photoLimit: 0)
            }))
        }
    }

    private func fetchRecords(beachID: UUID, filter: RecordFilter) -> Effect<Action> {
        .run { send in
            await send(.recordsResponse(Result {
                try await beachClient.fetchBeachRecords(beachID, filter.recordType)
            }))
        }
        .cancellable(id: CancelID.records, cancelInFlight: true)
    }
}

// MARK: - Types

enum LoadState<Value: Equatable>: Equatable {
    case loading
    case loaded(Value)
    case empty
    case failed
}

enum RecordFilter: Equatable, CaseIterable {
    case all
    case plobbing
    case plogging

    var title: String {
        switch self {
        case .all: "전체"
        case .plobbing: RecordType.plobbing.name
        case .plogging: RecordType.plogging.name
        }
    }

    var recordType: RecordType? {
        switch self {
        case .all: nil
        case .plobbing: .plobbing
        case .plogging: .plogging
        }
    }
}

enum SortOption: Equatable, CaseIterable {
    case latest
    case popular

    var title: String {
        switch self {
        case .latest: "최신순"
        case .popular: "인기순"
        }
    }
}
