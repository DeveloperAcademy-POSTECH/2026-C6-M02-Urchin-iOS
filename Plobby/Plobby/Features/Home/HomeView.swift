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
    
    @State private var cardHeight: CGFloat = 0
    @State private var walkDragStart: (progress: Double, translation: CGFloat)?
    @State private var dragAxis: Axis?
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            scene

            goalCard(isExpanded: false)
                .hidden()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    cardHeight = height
                }
                .padding(.horizontal, 20.scaled)

            goalCard(isExpanded: store.isGoalExpanded)
                .padding(.horizontal, 20.scaled)

            activityToggleButton
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20.scaled)
                .padding(.bottom, 8.scaled)
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

// MARK: - 장면

private extension HomeView {
    
    var scene: some View {
        let type = store.selectedType
        let days = store.board?.days ?? []
        let pulse = store.collectPulses[type, default: 0]

        return ZStack {
            switch type {
            case .plogging:
                sceneLayer(backdrop: .homeSceneBeach) {
                    PloggingSceneView(
                        days: days,
                        stage: store.stage,
                        collectPulse: pulse,
                        walkProgress: store.walkProgress
                    )
                }
                .transition(.move(edge: .leading))
            case .plobbing:
                sceneLayer(backdrop: .homeSceneSky) {
                    PlobbingSceneView(
                        days: days,
                        stage: store.stage,
                        collectPulse: pulse,
                        walkProgress: store.walkProgress
                    )
                }
                .transition(.move(edge: .trailing))
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
                onTrashSummaryTapped: { store.send(.trashSummaryButtonTapped, transaction: Self.noAnimation) }
            )
            .padding(.top, cardHeight)

            if store.isScrollGuideVisible {
                HomeScrollGuideToast()
                    .transition(.opacity)
            }
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(walkGesture)
        .animation(.easeInOut(duration: 0.2), value: store.isScrollGuideVisible)
    }

    var walkGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let axis = dragAxis ?? (abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical)
                dragAxis = axis
                guard axis == .vertical else { return }

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
            .onEnded { value in
                defer {
                    walkDragStart = nil
                    dragAxis = nil
                }
                guard dragAxis == .horizontal else { return }

                switchTab(by: value.predictedEndTranslation.width)
            }
    }

    func switchTab(by translation: CGFloat) {
        guard abs(translation) > Self.tabSwipeThreshold,
              let index = Self.tabs.firstIndex(of: store.selectedType)
        else { return }

        let nextIndex = index + (translation < 0 ? 1 : -1)
        guard Self.tabs.indices.contains(nextIndex) else { return }

        store.send(.activityTabSelected(Self.tabs[nextIndex]), animation: .smooth(duration: 0.3))
    }
    
    var walkPath: HomeWalkPath {
        let lastDay = max((store.board?.days.count ?? 1) - 1, 0)
        
        switch store.selectedType {
        case .plogging: return PloggingSceneView.walkPath(lastDay: lastDay)
        case .plobbing: return PlobbingSceneView.walkPath(lastDay: lastDay, stage: store.stage)
        }
    }
    
    func sceneLayer<Scene: View>(
        backdrop: ImageResource,
        @ViewBuilder scene: () -> Scene
    ) -> some View {
        ZStack(alignment: .top) {
            HomeSceneBackdrop(image: backdrop)
                .ignoresSafeArea()

            scene()
                .padding(.top, cardHeight)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    var activityToggleButton: some View {
        let type = store.selectedType
        let next: RecordType = type == .plogging ? .plobbing : .plogging

        return Button {
            store.send(.activityTabSelected(next), animation: .smooth(duration: 0.35))
        } label: {
            Image(systemName: type == .plogging ? "figure.walk" : "figure.open.water.swim")
                .font(.system(size: 24.scaled))
                .foregroundStyle(Color(.currentBrandText))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 48.scaled, height: 48.scaled)
                .background(Color(.gray0), in: Circle())
                .shadow(color: Color(.neutralBlack).opacity(0.1), radius: 6.scaled, y: 2.scaled)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(next.name)로 바꾸기")
    }
}

// MARK: - 공통 목표

private extension HomeView {
    
    @ViewBuilder
    func goalCard(isExpanded: Bool) -> some View {
        if let goal = store.board?.goal, let status = store.status {
            HomeGoalCard(
                goal: goal,
                status: status,
                isExpanded: isExpanded,
                onToggle: { store.send(.goalCardToggleTapped, animation: .easeInOut(duration: 0.25)) },
                onRecordTapped: { store.send(.recordButtonTapped, transaction: Self.noAnimation) },
                onAllGoalsTapped: { store.send(.allGoalsButtonTapped) },
                onParticipantsTapped: { store.send(.participantsButtonTapped) }
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
        if let goal = store.board?.goal {
            switch sheet {
            case .participants:
                HomeParticipantsSheet(
                    goal: goal,
                    participants: store.allParticipants,
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
    static let tabSwipeThreshold: CGFloat = 60
    
    static var noAnimation: Transaction {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }
}
