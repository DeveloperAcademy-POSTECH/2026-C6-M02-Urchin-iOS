//
//  HomeView.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

import ComposableArchitecture

struct HomeView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<HomeFeature>
    
    @Namespace private var tabUnderline
    /// 끌기 시작한 곳이에요. 쓰레기를 줍고 나면 그 자리에서 다시 시작해요.
    @State private var walkDragStart: (progress: Double, translation: CGFloat)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            goalCard
                .padding(.horizontal, 20.scaled)
            
            activityTabs
                .padding(.top, 4.scaled)
            
            scene
        }
        .background(Color(.gray0))
        .sheet(item: sheetBinding) { sheet in
            sheetContent(sheet)
        }
        .fullScreenCover(isPresented: activityPickerBinding) {
            HomeActivityPicker(
                onSelect: { type in
                    store.send(.activityPicked(type), transaction: Self.noAnimation)
                },
                onDismiss: {
                    store.send(.activityPickerDismissed, transaction: Self.noAnimation)
                }
            )
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: trashSummaryBinding) {
            if let board = store.board {
                HomeTrashSummaryPopup(board: board) {
                    store.send(.trashSummaryDismissed, transaction: Self.noAnimation)
                }
                .presentationBackground(.clear)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - 헤더

private extension HomeView {
    
    var header: some View {
        HStack {
            Image(.homeLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 73.scaled, height: 23.scaled)
                .accessibilityLabel("plobby")
            
            Spacer()
            
            Button {
                store.send(.notificationButtonTapped)
            } label: {
                Image(.bell)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24.scaled, height: 24.scaled)
                    .frame(width: 44.scaled, height: 44.scaled)
            }
            .accessibilityLabel("알림")
        }
        .padding(.leading, 20.scaled)
        .padding(.trailing, 12.scaled)
        .frame(height: 50.scaled)
    }
    
    var activityTabs: some View {
        HStack(spacing: 0) {
            ForEach(Self.tabs, id: \.self) { type in
                let isSelected = store.selectedType == type
                
                Button {
                    store.send(.activityTabSelected(type), animation: .smooth(duration: 0.3))
                } label: {
                    Text(type.name)
                        .plobbyFont(isSelected ? .actionLabel : .body)
                        .foregroundStyle(isSelected ? Color(.textPrimary) : Color(.textSecondary))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48.scaled)
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Rectangle()
                                    .fill(Color(.green500))
                                    .frame(height: 4.scaled)
                                    .matchedGeometryEffect(id: "underline", in: tabUnderline)
                                    .offset(y: 4.scaled)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.bottom, 4.scaled)
        .background(Color(.gray0))
    }
}

// MARK: - 장면

private extension HomeView {
    
    var scene: some View {
        let type = store.selectedType
        let days = store.board?.days ?? []
        let pulse = store.collectPulses[type, default: 0]
        
        return ZStack {
            switch type {
            case .plogging:
                PloggingSceneView(days: days, stage: store.stage, collectPulse: pulse, walkProgress: store.walkProgress)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.opacity)
            case .plobbing:
                PlobbingSceneView(days: days, stage: store.stage, collectPulse: pulse, walkProgress: store.walkProgress)
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.opacity)
            }
            
            if let status = store.status, status.isFinished {
                HomeGoalCelebration(isAchieved: status == .achieved)
                    .transition(.opacity)
            }
            
            HomeSceneOverlay(
                recordType: type,
                stage: store.stage,
                day: store.currentDay,
                totalTrashCount: store.board?.totalTrashCount ?? 0,
                isGoalFinished: store.isGoalFinished,
                isAtDay: store.walkProgress == store.walkProgress.rounded(),
                onParticipantsTapped: { store.send(.participantsButtonTapped) },
                onTrashSummaryTapped: { store.send(.trashSummaryButtonTapped, transaction: Self.noAnimation) }
            )
            
            if store.isScrollGuideVisible {
                HomeScrollGuideToast()
                    .transition(.opacity)
            }
            
            recordButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20.scaled)
                .padding(.bottom, 8.scaled)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(walkGesture)
        .animation(.easeInOut(duration: 0.2), value: store.isScrollGuideVisible)
    }
    
    /// 손가락을 올리면 사람이 해변 아래로 걸어가고, 내리면 뒤로 걸어가요.
    var walkGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !store.isWalkLocked else {
                    walkDragStart = nil
                    return
                }
                
                let translation = value.translation.height
                let start = walkDragStart ?? (store.walkProgress, translation)
                walkDragStart = start
                
                let progress = walkPath.progress(from: start.progress, moving: start.translation - translation)
                store.send(.sceneWalked(to: progress), animation: .easeInOut(duration: 0.3))
            }
            .onEnded { _ in
                walkDragStart = nil
            }
    }
    
    var walkPath: HomeWalkPath {
        let lastDay = max((store.board?.days.count ?? 1) - 1, 0)
        
        switch store.selectedType {
        case .plogging: return PloggingSceneView.walkPath(lastDay: lastDay)
        case .plobbing: return PlobbingSceneView.walkPath(lastDay: lastDay, stage: store.stage)
        }
    }
    
    var recordButton: some View {
        Button {
            store.send(.recordButtonTapped, transaction: Self.noAnimation)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24.scaled, weight: .medium))
                .foregroundStyle(Color(.currentBrandText))
                .frame(width: 56.scaled, height: 56.scaled)
                .background(Color(.gray0), in: Circle())
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("기록하기")
    }
}

// MARK: - 공통 목표

private extension HomeView {
    
    @ViewBuilder
    var goalCard: some View {
        if let goal = store.board?.goal, let status = store.status {
            HomeGoalCard(
                goal: goal,
                status: status,
                isExpanded: store.isGoalExpanded,
                onToggle: { store.send(.goalCardToggleTapped, animation: .easeInOut(duration: 0.25)) },
                onRecordTapped: { store.send(.recordButtonTapped, transaction: Self.noAnimation) },
                onAllGoalsTapped: { store.send(.allGoalsButtonTapped) }
            )
        }
    }
}

// MARK: - 시트

private extension HomeView {
    
    var sheetBinding: Binding<HomeFeature.Sheet?> {
        Binding(
            get: { store.sheet },
            set: { if $0 == nil { store.send(.sheetDismissed) } }
        )
    }
    
    var trashSummaryBinding: Binding<Bool> {
        Binding(
            get: { store.isTrashSummaryPresented },
            set: { if !$0 { store.send(.trashSummaryDismissed, transaction: Self.noAnimation) } }
        )
    }
    
    var activityPickerBinding: Binding<Bool> {
        Binding(
            get: { store.isActivityPickerPresented },
            set: { if !$0 { store.send(.activityPickerDismissed, transaction: Self.noAnimation) } }
        )
    }
    
    @ViewBuilder
    func sheetContent(_ sheet: HomeFeature.Sheet) -> some View {
        if let board = store.board {
            switch sheet {
            case .participants:
                HomeParticipantsSheet(
                    board: board,
                    now: store.now,
                    onParticipantTapped: { store.send(.participantTapped($0)) },
                    onClose: { store.send(.sheetDismissed) }
                )
            }
        }
    }
}

// MARK: - Constants

private extension HomeView {
    
    static let tabs: [RecordType] = [.plogging, .plobbing]
    
    static var noAnimation: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}
