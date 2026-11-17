//
//  RecordFlowFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/3/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
@Suite(.serialized)
struct RecordFlowFeatureTests {

    private let now = Date(timeIntervalSince1970: 1_793_000_000)

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    // MARK: - 단계 전환

    @Test
    func 사진_선택을_건너뛰면_기록하기로_이동한다() async {
        let store = makeStore(step: .photoPicker(PhotosPickerFeature.State(recordType: .plogging)))

        await store.send(\.step.photoPicker.bottomButtonTapped)
        await store.receive(\.step.photoPicker.delegate.finished) {
            $0.step = .form(RecordFormFeature.State(
                recordType: .plogging,
                period: .defaultPeriod(endingAt: now, calendar: calendar)
            ))
        }
    }

    @Test
    func 필수_항목만_입력하고_저장하면_리워드로_이동한다() async {
        var trash = TrashSelection()
        trash[.plastic] = 3
        var form = RecordFormFeature.State(recordType: .plobbing)
        form.photos = [.remote(storageKey: "photo", url: nil)]
        form.beach = Beach(id: UUID(), region: .east, name: "영일대 해수욕장", address: "", latitude: 0, longitude: 0)
        form.period = ActivityPeriod(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 3600))
        form.trash = trash
        form.totalWeightText = "2"
        form.memo = "깨끗해졌어요"
        let store = makeStore(step: .form(form))

        await store.send(\.step.form.completeTapped) {
            $0.step.modify(\.form) { $0.isSubmitting = true }
        }
        await store.receive(\.step.form.submitResponse.success) {
            $0.step.modify(\.form) {
                $0.isSubmitting = false
                $0.isCompleteEnabled = true
            }
        }
        await store.receive(\.step.form.delegate.recordCreated) {
            $0.step = .collecting(RecordCollectingFeature.State(recordID: UUID(0), beachName: "영일대 해수욕장", trash: trash, weightKg: 2))
        }
        // 닉네임과 공동 목표는 끝나는 대로 따로 오기 때문에 순서를 정하지 않고 넘겨요. 값은 아래 미리 받기 테스트에서 확인해요.
        await store.finish()
        await store.skipReceivedActions()
    }

    @Test
    func 쓰레기_모으기가_끝나면_리워드로_이동한다() async {
        let trash = TrashSelection()
        let store = makeStore(step: .collecting(RecordCollectingFeature.State(recordID: UUID(0), beachName: "영일대 해수욕장", trash: trash, weightKg: 2)))

        await store.send(\.step.collecting.delegate.finished) {
            $0.step = .reward(RecordRewardFeature.State(recordID: UUID(0), beachName: "영일대 해수욕장", trash: trash, weightKg: 2))
        }
    }

    @Test
    func 리워드에서_다음을_누르면_상세로_이동한다() async {
        let store = makeStore(step: .reward(RecordRewardFeature.State(recordID: UUID(0))))

        await store.send(\.step.reward.nextButtonTapped)
        await store.receive(\.step.reward.delegate.finished) {
            $0.step = .detail(RecordDetailFeature.State(recordID: UUID(0), myProfileTap: .ignored))
        }
    }

    // MARK: - 닫기

    @Test
    func 사진_선택에서_닫으면_기록_플로우가_종료된다() async {
        let store = makeStore(step: .photoPicker(PhotosPickerFeature.State(recordType: .plogging)))

        await store.send(\.step.photoPicker.closeTapped)
        await store.receive(\.step.photoPicker.delegate.cancelled)
        await store.receive(\.delegate.closed)
    }

    @Test
    func 기록하기에서_닫으면_기록_플로우가_종료된다() async {
        let store = makeStore(step: .form(RecordFormFeature.State(recordType: .plogging)))

        await store.send(\.step.form.closeTapped)
        await store.receive(\.step.form.delegate.closed)
        await store.receive(\.delegate.closed)
    }

    @Test
    func 리워드에서_닫으면_기록_플로우가_종료된다() async {
        let store = makeStore(step: .reward(RecordRewardFeature.State(recordID: UUID(0))))

        await store.send(\.step.reward.closeButtonTapped)
        await store.receive(\.step.reward.delegate.closed)
        await store.receive(\.delegate.closed)
    }

    @Test
    func 기록상세에서_닫으면_기록_플로우가_종료된다() async {
        let store = makeStore(step: .detail(RecordDetailFeature.State(recordID: UUID(0), myProfileTap: .ignored)))

        await store.send(\.step.detail.backTapped)
        await store.receive(\.step.detail.delegate.closed)
        await store.receive(\.delegate.closed)
    }

    // MARK: - 리워드 미리 받기

    @Test
    func 저장하면_모으기_동안_닉네임과_공동_목표를_미리_받아_리워드에_넘긴다() async {
        @Shared(.myProfile) var myProfile
        let profile = Profile(userID: UUID(1), nickname: "바다산책", profileImageKey: nil, profileImageURL: nil)
        let goal = Goal.fixture()
        let store = makeStore(step: .form(RecordFormFeature.State(recordType: .plogging)), profile: profile, goal: goal)
        store.exhaustivity = .off

        await store.send(.step(.form(.delegate(.recordCreated(recordID: UUID(0), beachName: nil, trash: TrashSelection(), weightKg: nil)))))
        await store.finish()

        #expect(myProfile == profile)
        #expect(store.state.prefetchedGoal == goal)

        await store.send(.step(.collecting(.delegate(.finished))))
        #expect(store.state.step.reward?.goal == goal)
    }

    @Test
    func 리워드로_넘어간_뒤_도착한_공동_목표도_리워드에_넘긴다() async {
        let goal = Goal.fixture()
        let store = makeStore(step: .reward(RecordRewardFeature.State(recordID: UUID(0))))

        await store.send(.goalPrefetched(.success(goal))) {
            $0.prefetchedGoal = goal
            $0.step.modify(\.reward) { $0.goal = goal }
        }
    }

    // MARK: - Helpers

    private func makeStore(
        step: RecordFlowFeature.Step.State,
        profile: Profile? = nil,
        goal: Goal? = nil
    ) -> TestStoreOf<RecordFlowFeature> {
        TestStore(initialState: RecordFlowFeature.State(recordType: .plogging, step: step)) {
            RecordFlowFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(now)
            $0.calendar = calendar
            $0.recordClient.submitRecord = { _ in }
            $0.userClient.fetchMyProfile = { profile }
            $0.goalClient.fetchCurrentGoal = { _ in goal }
            $0.locale = Locale(identifier: "ko_KR")
        }
    }
}
