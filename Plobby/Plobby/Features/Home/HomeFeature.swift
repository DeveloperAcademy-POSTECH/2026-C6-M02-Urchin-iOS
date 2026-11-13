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
        @Presents var goalList: GoalListFeature.State?
        @Presents var userHome: UserHomeFeature.State?
        
        var selectedType: RecordType = .plogging
        var boards: [RecordType: HomeGoalBoard] = [:]
        var statuses: [RecordType: HomeGoalStatus] = [:]
        var stages: [RecordType: HomeSceneStage] = [:]
        var walkProgresses: [RecordType: Double] = [:]
        var todayDays: [RecordType: Int] = [:]
        var isGoalExpanded = false
        var hasSetInitialGoalExpansion = false
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
        
        var walkProgress: Double {
            walkProgresses[selectedType] ?? 0
        }
        
        var isWalkLocked: Bool {
            transitioningTypes.contains(selectedType) || isGoalFinished
        }
        
        var status: HomeGoalStatus? {
            statuses[selectedType]
        }
        
        var currentUserID: UUID? {
            if case let .member(user) = membershipStatus { user.id } else { nil }
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
        case sceneWalked(to: Double)
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
        case userHomeOpened(GoalParticipant)
        case sheetDismissed
        case recordDetail(PresentationAction<RecordDetailFeature.Action>)
        case goalList(PresentationAction<GoalListFeature.Action>)
        case userHome(PresentationAction<UserHomeFeature.Action>)
        case delegate(Delegate)
        
        enum Delegate {
            case recordStarted(RecordType)
            case myProfileRequested
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.goalClient) var goalClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce {
            state,
            action in
            switch action {
            case .onAppear:
                // 홈에 들어올 때마다 공동 목표 카드는 접힌 상태로 보여줘요
                state.isGoalExpanded = false
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
                    state.walkProgresses[type] = status.isFinished ? Double(board.days.count) : Double(today)
                }
                if !state.hasSetInitialGoalExpansion, let goal = boards.first?.goal {
                    state.hasSetInitialGoalExpansion = true
                    state.isGoalExpanded = goal.collectedCount == 0
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
                state.hasSetInitialGoalExpansion = true
                state.isGoalExpanded = false
                return showScrollGuideIfNeeded(&state)
                
            case let .sceneWalked(target):
                let type = state.selectedType
                guard let board = state.boards[type],
                      !board.days.isEmpty,
                      !state.transitioningTypes.contains(type),
                      state.statuses[type]?.isFinished == false
                else { return .none }
                
                let lastDay = board.days.count - 1
                let stage = state.stages[type] ?? .arrived(day: 0)
                let collectedThrough = stage.collectedThrough(lastDay: lastDay)
                let current = state.walkProgresses[type] ?? 0
                let progress = min(max(target, -1), Double(lastDay + 1))
                let nextStop = collectedThrough + 1
                state.isScrollGuideVisible = false
                
                if progress > current, progress >= Double(nextStop) {
                    state.walkProgresses[type] = Double(nextStop)
                    return collect(at: nextStop, type: type, lastDay: lastDay, state: &state)
                }
                
                state.walkProgresses[type] = progress
                let day = min(max(Int(progress.rounded()), 0), lastDay)
                let collected = min(collectedThrough, Int(progress.rounded(.down)))
                let walkingStage: HomeSceneStage = collected >= day ? .collected(day: day) : .arrived(day: day)
                if walkingStage != stage {
                    state.stages[type] = walkingStage
                }
                return .none
                
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
                state.hasSetInitialGoalExpansion = true
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
                
            case let .participantTapped(participantID):
                guard let participant = state.board?.participants.first(
                    where: { $0.id == participantID}
                ),
                      !participant.isBlocked
                else { return .none }
                
                state.sheet = nil

                if participant.id == state.currentUserID {
                    return .run { send in
                        try await clock.sleep(for: Self.sheetDismissDelay)
                        await send(.delegate(.myProfileRequested))
                    }
                }

                return .run { send in
                    try await clock.sleep(for: Self.sheetDismissDelay)
                    await send(.userHomeOpened(participant))
                }
                
            case let .userHomeOpened(participant):
                state.userHome = UserHomeFeature.State(
                    userID: participant.id,
                    nickname: participant.nickname,
                    profileImageURL: participant.profileImageURL
                )
                return .none
                
            case .sheetDismissed:
                state.sheet = nil
                return .none
                
            case .recordDetail(.presented(.delegate(.closed))):
                state.recordDetail = nil
                return .none
                
            case .recordDetail(.presented(.delegate(.deleted))),
                    .recordDetail(.presented(.delegate(.blocked))):
                state.recordDetail = nil
                return .none
                
            case .goalList(.presented(.delegate(.closed))):
                state.goalList = nil
                return .none
                
            case .userHome(.presented(.delegate(.closed))):
                state.userHome = nil
                return .none
                
            case .userHome(.presented(.delegate(.blocked))):
                state.userHome = nil
                return .send(.onAppear)
                
            case .recordDetail,
                    .goalList,
                    .userHome,
                    .delegate:
                return .none
            }
        }
        .ifLet(\.$recordDetail, action: \.recordDetail) {
            RecordDetailFeature()
        }
        .ifLet(\.$goalList, action: \.goalList) {
            GoalListFeature()
        }
        .ifLet(\.$userHome, action: \.userHome) {
            UserHomeFeature()
        }
    }
}

// MARK: - Functions

extension HomeFeature {
    
    static let transitionDuration: Duration = .milliseconds(700)
    static let autoAdvanceDelay: Duration = .milliseconds(160)
    static let transitionAnimation: Animation = .smooth(duration: 0.7)
    private static let scrollGuideDuration: Duration = .seconds(3)
    private static let sheetDismissDelay: Duration = .milliseconds(350)
    
    private nonisolated enum CancelID: Hashable {
        case boards
        case scene(RecordType)
        case scrollGuide
    }
    
    private func collect(at stop: Int, type: RecordType, lastDay: Int, state: inout State) -> Effect<Action> {
        let stages: [HomeSceneStage] = stop > lastDay
        ? (0...type.resultStep).map { .finale(step: $0) }
        : [.collecting(day: stop), .collected(day: stop)]
        
        state.transitioningTypes.insert(type)
        return .run { send in
            for stage in stages {
                await send(.sceneStageAdvanced(type, stage), animation: HomeFeature.transitionAnimation)
                try await clock.sleep(for: HomeFeature.transitionDuration + HomeFeature.autoAdvanceDelay)
            }
            await send(.sceneTransitionFinished(type))
        }
        .cancellable(id: CancelID.scene(type), cancelInFlight: true)
    }
    
    private func apply(_ stage: HomeSceneStage, to type: RecordType, state: inout State) {
        state.stages[type] = stage
        if stage.isCollected {
            state.collectPulses[type, default: 0] += 1
        }
    }
    
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
        // 모은 쓰레기가 0개면 내려가며 볼 기록이 없어서 안내하지 않아요
        guard state.stage == .arrived(day: state.todayDays[state.selectedType] ?? 0),
              state.status?.isFinished == false,
              (state.board?.totalTrashCount ?? 0) > 0
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
