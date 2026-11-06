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
        /// 저장된 세션을 확인하는 중이에요.
        case launching
        case onboarding(OnboardingFeature.State)
        case signUp(SignUpFeature.State)
        case mainTab(MainTabFeature.State)
    }
    
    // MARK: - Action
    
    enum Action {
        case task
        case sessionRestored(Result<SignInResult?, any Error>)
        case sessionEnded
        case deviceTokenReceived(String)
        case pushTapped(UUID)
        case onboarding(OnboardingFeature.Action)
        case signUp(SignUpFeature.Action)
        case mainTab(MainTabFeature.Action)
    }

    private static let beachSyncInterval: TimeInterval = 60 * 60 * 24

    // MARK: - Dependency

    @Dependency(\.authClient) var authClient
    @Dependency(\.userClient) var userClient
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
                    restoreSession(),
                    observeSignedOutEvents(),
                    observeDeviceTokens(),
                    observeTappedRecordIDs(),
                    syncBeaches()
                )

            case let .sessionRestored(.success(.member(user))):
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return submitCurrentDeviceToken()

            case let .sessionRestored(.success(.newUser(user, fullName))):
                state = .signUp(SignUpFeature.State(user: user, fullName: fullName))
                return .none

            case let .sessionRestored(.failure(error)):
                PlobbyLogger.error(error)
                state = .onboarding(OnboardingFeature.State())
                return .none

            case .sessionRestored(.success(nil)):
                state = .onboarding(OnboardingFeature.State())
                return .none
                
            case .sessionEnded:
                @Shared(.membershipStatus) var membershipStatus

                switch state {
                case .launching, .signUp:
                    break
                case .mainTab where membershipStatus != .guest:
                    break
                default:
                    return .none
                }

                updateMembershipStatus(.guest)
                state = .onboarding(OnboardingFeature.State())
                return .cancel(id: CancelID.restoreSession)

            case let .deviceTokenReceived(token):
                @Shared(.membershipStatus) var membershipStatus
                @Shared(.isPushEnabled) var isPushEnabled
                guard case .member = membershipStatus, isPushEnabled else { return .none }

                return submitDeviceToken(token)

            // TODO: 앱이 꺼진 상태에서 푸시로 열면 로그인 복원(#96) 후 이동 연결
            case let .pushTapped(recordID):
                guard case .mainTab = state else { return .none }

                return .send(.mainTab(.pushTapped(recordID)))

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

            case .mainTab(.delegate(.signedOut)):
                updateMembershipStatus(.guest)
                state = .onboarding(OnboardingFeature.State())
                return .none

            case let .mainTab(.signIn(.delegate(.signedIn(user)))):
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return .merge(
                    submitCurrentDeviceToken(),
                    .send(.mainTab(.home(.onAppear)))
                )

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

    private nonisolated enum CancelID {
        case restoreSession
    }

    private func restoreSession() -> Effect<Action> {
        .run { [authClient, userClient] send in
            await send(.sessionRestored(Result {
                guard let user = await authClient.fetchCurrentUser() else { return nil }

                let profile = try await userClient.fetchMyProfile()
                return profile != nil ? .member(user) : .newUser(user, fullName: user.fullName)
            }))
        }
        .cancellable(id: CancelID.restoreSession)
    }

    private func observeSignedOutEvents() -> Effect<Action> {
        .run { [authClient] send in
            for await _ in authClient.signedOutEvents() {
                await send(.sessionEnded)
            }
        }
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

    /// 회원이 된 직후에 불러요. 알림 권한을 요청하고, 허용되면 기기 토큰을 등록해요.
    /// 설정에서 알림을 끈 기기는 건너뛰어요.
    private func submitCurrentDeviceToken() -> Effect<Action> {
        @Shared(.isPushEnabled) var isPushEnabled
        guard isPushEnabled else { return .none }

        return .run { _ in
            guard try await pushClient.requestAuthorization() else { return }

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
