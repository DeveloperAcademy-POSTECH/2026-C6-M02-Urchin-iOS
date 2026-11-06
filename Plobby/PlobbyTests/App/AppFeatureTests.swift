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

    private let user = AuthUser(id: UUID(0), email: "plobby@example.com", fullName: "플로비")

    // MARK: - 세션 복원

    @Test
    func 세션과_프로필이_있으면_회원으로_메인탭에_들어간다() async {
        let submittedToken = LockIsolated<String?>(nil)
        let store = makeStore(initialState: .launching) {
            $0.pushClient = .mock(fetchToken: { "device-token" })
            $0.notificationClient = .mock(submitDeviceToken: { token in submittedToken.setValue(token) })
        }

        await store.send(.sessionRestored(.success(.member(user)))) {
            $0 = .mainTab(MainTabFeature.State(home: HomeFeature.State()))
        }
        await store.finish()

        #expect(store.state.mainTab?.membershipStatus == .member(user))
        #expect(submittedToken.value == "device-token")
    }

    @Test
    func 세션은_있지만_프로필이_없으면_회원가입으로_이동한다() async {
        let store = makeStore(initialState: .launching)

        await store.send(.sessionRestored(.success(.newUser(user, fullName: "플로비")))) {
            $0 = .signUp(SignUpFeature.State(user: self.user, fullName: "플로비"))
        }
    }

    @Test
    func 세션이_없으면_온보딩으로_이동한다() async {
        let store = makeStore(initialState: .launching)

        await store.send(.sessionRestored(.success(nil))) {
            $0 = .onboarding(OnboardingFeature.State())
        }
    }

    @Test
    func 세션_확인에_실패하면_온보딩으로_이동한다() async {
        struct FetchFailure: Error {}
        let store = makeStore(initialState: .launching)

        await store.send(.sessionRestored(.failure(FetchFailure()))) {
            $0 = .onboarding(OnboardingFeature.State())
        }
    }

    // MARK: - 세션 종료

    @Test
    func 회원의_세션이_끝나면_비회원으로_온보딩에_이동한다() async {
        let mainTab = MainTabFeature.State(home: HomeFeature.State())
        mainTab.$membershipStatus.withLock { $0 = .member(user) }
        let store = makeStore(initialState: .mainTab(mainTab))

        await store.send(.sessionEnded) {
            $0 = .onboarding(OnboardingFeature.State())
        }

        @Shared(.membershipStatus) var membershipStatus
        #expect(membershipStatus == .guest)
    }

    @Test
    func 비회원일_때_세션이_끝나면_무시한다() async {
        let mainTab = MainTabFeature.State(home: HomeFeature.State())
        mainTab.$membershipStatus.withLock { $0 = .guest }
        let store = makeStore(initialState: .mainTab(mainTab))

        await store.send(.sessionEnded)
    }

    @Test(arguments: [
        AppFeature.State.launching,
        .onboarding(OnboardingFeature.State()),
    ])
    func 로그인_전_화면에서_세션이_끝나면_무시한다(initialState: AppFeature.State) async {
        let store = makeStore(initialState: initialState)

        await store.send(.sessionEnded)
    }
}

// MARK: - Helpers

private extension AppFeatureTests {

    func makeStore(
        initialState: AppFeature.State,
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<AppFeature> {
        TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            dependencies(&$0)
        }
    }
}

// MARK: - Mock

private extension PushClient {

    static func mock(fetchToken: @escaping @Sendable () async throws -> String) -> Self {
        PushClient(
            requestAuthorization: { true },
            fetchToken: fetchToken,
            tokens: { AsyncStream { $0.finish() } },
            tappedRecordIDs: { AsyncStream { $0.finish() } }
        )
    }
}

private extension NotificationClient {

    static func mock(submitDeviceToken: @escaping @Sendable (String) async throws -> Void) -> Self {
        NotificationClient(
            fetchNotifications: { [] },
            updateReadAt: { _ in },
            updateAllReadAt: {},
            submitDeviceToken: submitDeviceToken
        )
    }
}
