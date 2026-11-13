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
        case login(LoginFeature.State)
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
        case login(LoginFeature.Action)
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

            // 이미 앱을 쓰던 회원은 온보딩을 본 것으로 쳐서, 로그아웃하면 로그인 화면으로 가요
            case let .sessionRestored(.success(.member(user))):
                markOnboardingSeen()
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return submitCurrentDeviceToken()

            case let .sessionRestored(.success(.newUser(user))):
                state = .signUp(SignUpFeature.State(user: user))
                return .none

            case let .sessionRestored(.failure(error)):
                PlobbyLogger.error(error)
                state = signedOutState()
                return .none

            case .sessionRestored(.success(nil)):
                state = signedOutState()
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
                state = signedOutState()
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

            case let .onboarding(.signIn(.delegate(.signedIn(user)))),
                 let .login(.signIn(.delegate(.signedIn(user)))):
                markOnboardingSeen()
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return submitCurrentDeviceToken()

            case let .onboarding(.signIn(.delegate(.needsSignUp(user)))),
                 let .login(.signIn(.delegate(.needsSignUp(user)))):
                markOnboardingSeen()
                state = .signUp(SignUpFeature.State(user: user))
                return .none

            case .onboarding(.delegate(.browseWithoutSignUp)),
                 .login(.delegate(.browseWithoutSignUp)):
                markOnboardingSeen()
                updateMembershipStatus(.guest)
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return .none

            case let .signUp(.delegate(.completed(user))):
                @Shared(.isHomeTutorialPending) var isHomeTutorialPending
                $isHomeTutorialPending.withLock { $0 = true }
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return submitCurrentDeviceToken()

            // 가입을 그만두면 로그인 화면으로 돌아가고, 남은 로그인 정보도 지워서 다음에 다시 가입 화면으로 오지 않게 해요.
            case .signUp(.delegate(.cancelled)):
                updateMembershipStatus(.guest)
                state = .login(LoginFeature.State())
                return .run { [authClient] _ in
                    try? await authClient.signOut(nil)
                }

            case .mainTab(.delegate(.signedOut)):
                updateMembershipStatus(.guest)
                state = .login(LoginFeature.State())
                return .none

            case let .mainTab(.signIn(.delegate(.signedIn(user)))):
                updateMembershipStatus(.member(user))
                state = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
                return .merge(
                    submitCurrentDeviceToken(),
                    .send(.mainTab(.home(.onAppear)))
                )

            case let .mainTab(.signIn(.delegate(.needsSignUp(user)))):
                state = .signUp(SignUpFeature.State(user: user))
                return .none

            case .onboarding, .login, .signUp, .mainTab:
                return .none
            }
        }
        .ifCaseLet(\.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        .ifCaseLet(\.login, action: \.login) {
            LoginFeature()
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

    /// 로그인하지 않은 상태로 보여줄 첫 화면이에요. 온보딩을 본 적 있으면 로그인 화면이에요.
    private func signedOutState() -> State {
        @Shared(.hasSeenOnboarding) var hasSeenOnboarding

        return hasSeenOnboarding ? .login(LoginFeature.State()) : .onboarding(OnboardingFeature.State())
    }

    /// 온보딩에서 로그인하거나 둘러보기로 넘어가면, 다음 실행부터는 로그인 화면을 보여줘요.
    private func markOnboardingSeen() {
        @Shared(.hasSeenOnboarding) var hasSeenOnboarding
        $hasSeenOnboarding.withLock { $0 = true }
    }

    private nonisolated enum CancelID {
        case restoreSession
    }

    private func restoreSession() -> Effect<Action> {
        .run { [authClient, userClient] send in
            await send(.sessionRestored(Result {
                guard let user = await authClient.fetchCurrentUser() else { return nil }

                let profile = try await userClient.fetchMyProfile()
                return profile != nil ? .member(user) : .newUser(user)
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
