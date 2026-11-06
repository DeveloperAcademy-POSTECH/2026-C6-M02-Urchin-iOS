//
//  AppFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/30/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct AppFeature {
    
    // MARK: - State
    
    @ObservableState
    enum State: Equatable {
        case onboarding(OnboardingFeature.State)
        case signUp(SignUpFeature.State)
        case mainTab(MainTabFeature.State)
    }
    
    // MARK: - Action
    
    enum Action {
        case task
        case deviceTokenReceived(String)
        case pushTapped(UUID)
        case onboarding(OnboardingFeature.Action)
        case signUp(SignUpFeature.Action)
        case mainTab(MainTabFeature.Action)
    }

    private static let beachSyncInterval: TimeInterval = 60 * 60 * 24

    // MARK: - Dependency

    @Dependency(\.pushClient) var pushClient
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.beachClient) var beachClient
    @Dependency(\.date.now) var now
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                return .merge(
                    observeDeviceTokens(),
                    observeTappedRecordIDs(),
                    syncBeaches()
                )

            case let .deviceTokenReceived(token):
                @Shared(.membershipStatus) var membershipStatus
                guard case .member = membershipStatus else { return .none }

                return submitDeviceToken(token)

            case let .pushTapped(recordID):
                // TODO: 기록 상세 화면 구현 후 이동 연결
                PlobbyLogger.debug("푸시 탭 기록 ID: \(recordID)")
                return .none

            case let .onboarding(.signIn(.delegate(.signedIn(user)))):
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return submitCurrentDeviceToken()

            case let .onboarding(.signIn(.delegate(.needsSignUp(user, fullName)))):
                state = .signUp(SignUpFeature.State(user: user, fullName: fullName))
                return .none

            case .onboarding(.delegate(.browseWithoutSignUp)):
                updateMembershipStatus(.guest)
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return .none

            case let .signUp(.delegate(.completed(user))):
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return submitCurrentDeviceToken()

            case let .mainTab(.signIn(.delegate(.signedIn(user)))):
                updateMembershipStatus(.member(user))
                return submitCurrentDeviceToken()

            case let .mainTab(.signIn(.delegate(.needsSignUp(user, fullName)))):
                state = .signUp(SignUpFeature.State(user: user, fullName: fullName))
                return .none

            case .onboarding, .signUp, .mainTab:
                return .none
            }
        }
        .ifCaseLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifCaseLet(\.signUp, action: \.signUp) {
            SignUpFeature()
        }
        .ifCaseLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
    }
}

// MARK: - Functions

extension AppFeature {

    private func updateMembershipStatus(_ status: MembershipStatus) {
        @Shared(.membershipStatus) var membershipStatus
        $membershipStatus.withLock { $0 = status }
    }

    private func observeDeviceTokens() -> Effect<Action> {
        .run { send in
            for await token in pushClient.tokens() {
                await send(.deviceTokenReceived(token))
            }
        }
    }

    private func observeTappedRecordIDs() -> Effect<Action> {
        .run { send in
            for await recordID in pushClient.tappedRecordIDs() {
                await send(.pushTapped(recordID))
            }
        }
    }

    private func submitDeviceToken(_ token: String) -> Effect<Action> {
        .run { _ in
            try await notificationClient.submitDeviceToken(token)
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }

    private func submitCurrentDeviceToken() -> Effect<Action> {
        .run { _ in
            let token = try await pushClient.fetchToken()
            try await notificationClient.submitDeviceToken(token)
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }

    private func syncBeaches() -> Effect<Action> {
        @Shared(.beachesSyncedAt) var beachesSyncedAt
        if let beachesSyncedAt, now.timeIntervalSince(beachesSyncedAt) < Self.beachSyncInterval {
            return .none
        }

        return .run { _ in
            let beaches = try await beachClient.fetchBeaches(nil)
            guard !beaches.isEmpty else { return }

            @Shared(.beaches) var allBeaches
            $allBeaches.withLock { $0 = beaches }
            $beachesSyncedAt.withLock { $0 = now }
        } catch: { error, _ in
            PlobbyLogger.error(error)
        }
    }
}
