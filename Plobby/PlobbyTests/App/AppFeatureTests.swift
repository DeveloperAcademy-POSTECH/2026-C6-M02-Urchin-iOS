//
//  AppFeatureTests.swift
//  PlobbyTests
//
//  Created by 이은지 on 11/6/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
@Suite(.serialized)
struct AppFeatureTests {

    private let user = AuthUser(id: UUID(0), email: "plobby@example.com")
    private let profile = Profile(userID: UUID(0), nickname: "플로비", profileImageKey: nil, profileImageURL: nil)

    // MARK: - 세션 복원

    @Test
    func 세션과_프로필이_있으면_회원으로_메인탭에_들어간다() async {
        let submittedToken = LockIsolated<String?>(nil)
        let store = makeStore(
            currentUser: user,
            fetchMyProfile: { profile },
            submitDeviceToken: { submittedToken.setValue($0) }
        )

        await store.send(.task)
        await store.receive(\.sessionRestored.success) {
            $0 = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
        }
        await store.finish()

        #expect(store.state.mainTab?.membershipStatus == .member(user))
        #expect(submittedToken.value == "device-token")
    }

    @Test
    func 세션은_있지만_프로필이_없으면_회원가입으로_이동한다() async {
        let store = makeStore(currentUser: user, fetchMyProfile: { nil })

        await store.send(.task)
        await store.receive(\.sessionRestored.success) {
            $0 = .signUp(SignUpFeature.State(user: self.user))
        }
        await store.finish()
    }

    @Test
    func 세션이_없으면_온보딩으로_이동한다() async {
        let store = makeStore(currentUser: nil)

        await store.send(.task)
        await store.receive(\.sessionRestored.success) {
            $0 = .onboarding(OnboardingFeature.State())
        }
        await store.finish()
    }

    @Test
    func 프로필_조회에_실패하면_온보딩으로_이동한다() async {
        let store = makeStore(currentUser: user, fetchMyProfile: { throw MockError() })

        await store.send(.task)
        await store.receive(\.sessionRestored.failure) {
            $0 = .onboarding(OnboardingFeature.State())
        }
        await store.finish()
    }

    // MARK: - 세션 종료

    @Test
    func 회원의_세션이_끝나면_비회원으로_온보딩에_이동한다() async {
        let (signedOutEvents, signOut) = AsyncStream<Void>.makeStream()
        let store = makeStore(
            currentUser: user,
            fetchMyProfile: { profile },
            signedOutEvents: signedOutEvents
        )

        await store.send(.task)
        await store.receive(\.sessionRestored.success) {
            $0 = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
        }

        signOut.yield()
        await store.receive(\.sessionEnded) {
            $0 = .onboarding(OnboardingFeature.State())
        }
        signOut.finish()
        await store.finish()

        @Shared(.membershipStatus) var membershipStatus
        #expect(membershipStatus == .guest)
    }

    @Test
    func 복원_중에_세션이_끝나면_복원_결과를_버리고_온보딩으로_이동한다() async {
        let (signedOutEvents, signOut) = AsyncStream<Void>.makeStream()
        let store = makeStore(
            currentUser: user,
            fetchMyProfile: {
                try await Task.sleep(for: .seconds(60))
                return nil
            },
            signedOutEvents: signedOutEvents
        )

        await store.send(.task)

        signOut.yield()
        await store.receive(\.sessionEnded) {
            $0 = .onboarding(OnboardingFeature.State())
        }
        signOut.finish()
        await store.finish()
    }

    @Test
    func 비회원일_때_세션이_끝나면_무시한다() async {
        let mainTab = MainTabFeature.State(home: HomeFeature.State())
        mainTab.$membershipStatus.withLock { $0 = .guest }
        let store = TestStore(initialState: .mainTab(mainTab)) {
            AppFeature()
        }

        await store.send(.sessionEnded)
    }

    @Test
    func 온보딩에서_세션이_끝나면_무시한다() async {
        let store = TestStore(initialState: .onboarding(OnboardingFeature.State())) {
            AppFeature()
        }

        await store.send(.sessionEnded)
    }
}

// MARK: - Helpers

private extension AppFeatureTests {

    func makeStore(
        currentUser: AuthUser?,
        fetchMyProfile: @escaping @Sendable () async throws -> Profile? = { nil },
        signedOutEvents: AsyncStream<Void> = .finished,
        submitDeviceToken: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) -> TestStoreOf<AppFeature> {
        TestStore(initialState: .launching) {
            AppFeature()
        } withDependencies: {
            $0.authClient = .mock(currentUser: currentUser, signedOutEvents: signedOutEvents)
            $0.userClient = .mock(fetchMyProfile: fetchMyProfile)
            $0.pushClient = .mock(fetchToken: { "device-token" })
            $0.notificationClient = .mock(submitDeviceToken: submitDeviceToken)
            $0.beachClient = .mock
            $0.date.now = Date(timeIntervalSince1970: 0)
        }
    }
}

// MARK: - Mock

private struct MockError: Error {}

private extension AsyncStream {

    static var finished: Self { AsyncStream { $0.finish() } }
}

private extension AuthClient {

    static func mock(currentUser: AuthUser?, signedOutEvents: AsyncStream<Void>) -> Self {
        AuthClient(
            signInWithApple: { _, _ in throw MockError() },
            fetchCredential: { _ in .failure(.failed) },
            fetchAppleAuthorizationCode: { throw MockError() },
            fetchCurrentUser: { currentUser },
            signedOutEvents: { signedOutEvents },
            signUp: { _ in throw MockError() },
            signOut: { _ in throw MockError() },
            submitWithdrawalFeedback: { _, _ in throw MockError() },
            withdraw: { _, _, _ in throw MockError() }
        )
    }
}

private extension UserClient {

    static func mock(fetchMyProfile: @escaping @Sendable () async throws -> Profile?) -> Self {
        UserClient(
            fetchIsNicknameAvailable: { _ in throw MockError() },
            fetchMyProfile: fetchMyProfile,
            updateMyProfile: { _, _ in throw MockError() },
            submitBlock: { _ in throw MockError() },
            removeBlock: { _ in throw MockError() },
            fetchBlockedUsers: { throw MockError() }
        )
    }
}

private extension PushClient {

    static func mock(fetchToken: @escaping @Sendable () async throws -> String) -> Self {
        PushClient(
            requestAuthorization: { true },
            fetchAuthorization: { .authorized },
            openNotificationSettings: {},
            fetchToken: fetchToken,
            tokens: { .finished },
            tappedRecordIDs: { .finished }
        )
    }
}

private extension NotificationClient {

    static func mock(submitDeviceToken: @escaping @Sendable (String) async throws -> Void) -> Self {
        NotificationClient(
            fetchNotifications: { [] },
            updateReadAt: { _ in },
            updateAllReadAt: {},
            submitDeviceToken: submitDeviceToken,
            removeDeviceToken: { _ in }
        )
    }
}

private extension BeachClient {

    static let mock = BeachClient(
        fetchBeaches: { _ in [] },
        fetchFavoriteBeaches: { [] },
        submitFavoriteBeach: { _ in },
        removeFavoriteBeach: { _ in },
        fetchRecordCounts: { [:] },
        fetchBeachRecords: { _, _ in [] }
    )
}
