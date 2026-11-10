//
//  HomeFeature.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

@Reducer
struct HomeFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        @Shared(.membershipStatus) var membershipStatus
        @Presents var recordDetail: RecordDetailFeature.State?
        @Presents var notification: NotificationFeature.State?
        @Presents var goalList: GoalListFeature.State?

        var selectedType: RecordType = .plogging
        var boards: [RecordType: HomeGoalBoard] = [:]
        /// 서버에서 받은 끝 시각·개수를 오늘과 비교해 정한 목표 상태예요.
        var statuses: [RecordType: HomeGoalStatus] = [:]
        var stages: [RecordType: HomeSceneStage] = [:]
        /// 오늘(오늘 기록이 없으면 가장 최근 기록일)에 해당하는 날짜 순서예요. 장면은 이 날짜에서 시작해요.
        var todayDays: [RecordType: Int] = [:]
        /// 공동 목표 카드는 화면 위에 하나라 플로깅·플로빙 탭이 펼침 상태를 같이 써요.
        var isGoalExpanded = false
        /// 수거가 끝날 때마다 올라가요. 봉투(수거망)가 출렁이는 애니메이션 트리거예요.
        var collectPulses: [RecordType: Int] = [:]
        var transitioningTypes: Set<RecordType> = []
        var sheet: Sheet?
        var isTrashSummaryPresented = false
        var isActivityPickerPresented = false
        var isScrollGuideVisible = false
        var now = Date.distantPast

        var board: HomeGoalBoard? {
            boards[selectedType]
        }

        var stage: HomeSceneStage {
            stages[selectedType] ?? .arrived(day: 0)
        }

        var currentDay: GoalDailyProgress? {
            guard let days = board?.days, !days.isEmpty else { return nil }
            return days[min(stage.day(lastDay: days.count - 1), days.count - 1)]
        }

        var status: HomeGoalStatus? {
            statuses[selectedType]
        }

        var isGoalFinished: Bool {
            status?.isFinished ?? false
        }
    }

    enum Sheet: Equatable, Identifiable {
        case participants

        var id: Self { self }
    }

    // MARK: - Action

    enum Action {
        case onAppear
        case boardsResponse(Result<[HomeGoalBoard], any Error>, now: Date)
        case activityTabSelected(RecordType)
        case sceneSwiped(forward: Bool)
        case sceneStageAdvanced(RecordType, HomeSceneStage)
        case sceneTransitionFinished(RecordType)
        case scrollGuideHidden
        case goalCardToggleTapped
        case recordButtonTapped
        case activityPicked(RecordType)
        case activityPickerDismissed
        case allGoalsButtonTapped
        case participantsButtonTapped
        case trashSummaryButtonTapped
        case trashSummaryDismissed
        case participantTapped(GoalParticipant.ID)
        case sheetDismissed
        case notificationButtonTapped
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case notification(PresentationAction<NotificationFeature.Action>)
        case goalList(PresentationAction<GoalListFeature.Action>)
        case delegate(Delegate)

        enum Delegate {
            case recordStarted(RecordType)
            case loginRequired
        }
    }

    // MARK: - Dependency

    @Dependency(\.goalClient) var goalClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    // MARK: - Body

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            if case .guest = state.membershipStatus, action.requiresLogin {
                return .send(.delegate(.loginRequired))
            }

            switch action {
            case .onAppear:
                let now = now
                return .run { send in
                    await send(.boardsResponse(Result { try await fetchBoards(now: now) }, now: now))
                }
                .cancellable(id: CancelID.boards, cancelInFlight: true)

            case let .boardsResponse(.success(boards), now):
                state.now = now
                state.transitioningTypes = []
                state.boards = [:]
                state.statuses = [:]
                for board in boards {
                    let type = board.recordType
                    let status = board.goal.homeStatus(at: now)
                    let today = todayDay(in: board.days, now: now)
                    state.boards[type] = board
                    state.statuses[type] = status
                    state.todayDays[type] = today
                    state.stages[type] = status.isFinished ? .finale(step: type.resultStep) : .arrived(day: today)
                }
                return .merge(
                    .merge(RecordType.allCases.map { .cancel(id: CancelID.scene($0)) }),
                    showScrollGuideIfNeeded(&state)
                )

            case let .boardsResponse(.failure(error), _):
                PlobbyLogger.error(error)
                return .none

            case let .activityTabSelected(type):
                state.selectedType = type
                return showScrollGuideIfNeeded(&state)

            case let .sceneSwiped(forward):
                let type = state.selectedType
                guard let board = state.boards[type],
                      !board.days.isEmpty,
                      !state.transitioningTypes.contains(type),
                      state.statuses[type]?.isFinished == false
                else { return .none }

                let lastDay = board.days.count - 1
                let stage = state.stages[type] ?? .arrived(day: 0)
                let stages = forward
                    ? type.forwardStages(from: stage, lastDay: lastDay)
                    : type.backwardStages(from: stage, lastDay: lastDay)
                guard let first = stages.first else { return .none }

                state.isScrollGuideVisible = false
                state.transitioningTypes.insert(type)
                apply(first, to: type, state: &state)

                return .run { send in
                    for next in stages.dropFirst() {
                        try await clock.sleep(for: HomeFeature.transitionDuration + HomeFeature.autoAdvanceDelay)
                        await send(.sceneStageAdvanced(type, next), animation: HomeFeature.transitionAnimation)
                    }
                    try await clock.sleep(for: HomeFeature.transitionDuration)
                    await send(.sceneTransitionFinished(type))
                }
                .cancellable(id: CancelID.scene(type), cancelInFlight: true)

            case let .sceneStageAdvanced(type, stage):
                apply(stage, to: type, state: &state)
                return .none

            case let .sceneTransitionFinished(type):
                state.transitioningTypes.remove(type)
                return .none

            case .scrollGuideHidden:
                state.isScrollGuideVisible = false
                return .none

            case .goalCardToggleTapped:
                state.isGoalExpanded.toggle()
                return .none

            case .recordButtonTapped:
                state.isActivityPickerPresented = true
                return .none

            case let .activityPicked(type):
                state.isActivityPickerPresented = false
                return .send(.delegate(.recordStarted(type)))

            case .activityPickerDismissed:
                state.isActivityPickerPresented = false
                return .none

            case .allGoalsButtonTapped:
                state.goalList = GoalListFeature.State(now: state.now)
                return .none

            case .participantsButtonTapped:
                state.sheet = .participants
                return .none

            case .trashSummaryButtonTapped:
                state.isTrashSummaryPresented = true
                return .none

            case .trashSummaryDismissed:
                state.isTrashSummaryPresented = false
                return .none

            // TODO: 마이 홈(프로필) 화면 디자인이 나오면 해당 사용자의 마이 홈으로 이동
            case .participantTapped:
                return .none

            case .sheetDismissed:
                state.sheet = nil
                return .none

            case .notificationButtonTapped:
                state.notification = NotificationFeature.State()
                return .none

            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return .none

            case .recordDetail(.presented(.delegate(.deleted))),
                 .recordDetail(.presented(.delegate(.reported))),
                 .recordDetail(.presented(.delegate(.blocked))):
                state.recordDetail = nil
                return .none

            case .goalList(.presented(.delegate(.closed))):
                state.goalList = nil
                return .none

            case .goalList(.presented(.delegate(.loginRequired))):
                return .send(.delegate(.loginRequired))

            case .recordDetail, .notification, .goalList, .delegate:
                return .none
            }
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$notification, action: \.notification) {
            NotificationFeature()
        }
        .ifLet(\.$goalList, action: \.goalList) {
            GoalListFeature()
        }
    }
}

// MARK: - Action

private extension HomeFeature.Action {

    var requiresLogin: Bool {
        switch self {
        case .recordButtonTapped, .notificationButtonTapped:
            true
        default:
            false
        }
    }
}

// MARK: - Functions

extension HomeFeature {

    static let transitionDuration: Duration = .milliseconds(700)
    static let autoAdvanceDelay: Duration = .milliseconds(160)
    static let transitionAnimation: Animation = .smooth(duration: 0.7)
    private static let scrollGuideDuration: Duration = .seconds(3)

    private nonisolated enum CancelID: Hashable {
        case boards
        case scene(RecordType)
        case scrollGuide
    }

    private func apply(_ stage: HomeSceneStage, to type: RecordType, state: inout State) {
        state.stages[type] = stage
        if stage.isCollected {
            state.collectPulses[type, default: 0] += 1
        }
    }

    /// 진행 중인 목표가 없으면 가장 최근 목표(끝난 목표)를 보여줘요. 목표가 하나도 없으면 빈 배열이에요.
    private func fetchBoards(now: Date) async throws -> [HomeGoalBoard] {
        let currentGoal = try await goalClient.fetchCurrentGoal(now)
        let goal: Goal? = if let currentGoal {
            currentGoal
        } else {
            try await goalClient.fetchGoals(now).first
        }
        guard let goal else { return [] }

        async let plogging = fetchBoard(goal: goal, recordType: .plogging)
        async let plobbing = fetchBoard(goal: goal, recordType: .plobbing)
        return try await [plogging, plobbing]
    }

    private func fetchBoard(goal: Goal, recordType: RecordType) async throws -> HomeGoalBoard {
        async let days = goalClient.fetchDailyProgresses(goal.id, recordType)
        async let trashSummaries = goalClient.fetchTrashSummaries(goal.id, recordType)
        async let participants = goalClient.fetchParticipants(goal.id, recordType)

        return try await HomeGoalBoard(
            goal: goal,
            recordType: recordType,
            days: days,
            trashSummaries: trashSummaries,
            participants: participants
        )
    }

    private func todayDay(in days: [GoalDailyProgress], now: Date) -> Int {
        let today = calendar.startOfDay(for: now)
        return days.lastIndex { calendar.startOfDay(for: $0.day) <= today } ?? 0
    }

    private func showScrollGuideIfNeeded(_ state: inout State) -> Effect<Action> {
        guard state.stage == .arrived(day: state.todayDays[state.selectedType] ?? 0),
              state.status?.isFinished == false
        else {
            state.isScrollGuideVisible = false
            return .cancel(id: CancelID.scrollGuide)
        }

        state.isScrollGuideVisible = true
        return .run { send in
            try await clock.sleep(for: HomeFeature.scrollGuideDuration)
            await send(.scrollGuideHidden, animation: .easeInOut)
        }
        .cancellable(id: CancelID.scrollGuide, cancelInFlight: true)
    }
}
