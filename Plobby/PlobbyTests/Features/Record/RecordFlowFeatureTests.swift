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
struct RecordFlowFeatureTests {

    // MARK: - 단계 전환

    @Test
    func 사진_선택을_건너뛰면_기록하기로_이동한다() async {
        let store = makeStore(step: .photoPicker(PhotosPickerFeature.State(recordType: .plogging)))

        await store.send(\.step.photoPicker.bottomButtonTapped)
        await store.receive(\.step.photoPicker.delegate.finished) {
            $0.step = .form(RecordFormFeature.State(recordType: .plogging))
        }
    }

    @Test
    func 필수_항목만_입력하고_저장하면_리워드로_이동한다() async {
        var form = RecordFormFeature.State(recordType: .plobbing)
        form.beach = Beach(id: UUID(), region: .east, name: "영일대 해수욕장", address: "", latitude: 0, longitude: 0)
        form.period = ActivityPeriod(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 3600))
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
            $0.step = .reward(RecordRewardFeature.State(recordID: UUID(0), beachName: "영일대 해수욕장"))
        }
    }

    @Test
    func 리워드에서_다음을_누르면_상세로_이동한다() async {
        let store = makeStore(step: .reward(RecordRewardFeature.State(recordID: UUID(0))))

        await store.send(\.step.reward.nextButtonTapped)
        await store.receive(\.step.reward.delegate.finished) {
            $0.step = .detail(RecordDetailFeature.State(recordID: UUID(0)))
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
        let store = makeStore(step: .detail(RecordDetailFeature.State(recordID: UUID(0))))

        await store.send(\.step.detail.closeButtonTapped)
        await store.receive(\.step.detail.delegate.closed)
        await store.receive(\.delegate.closed)
    }

    // MARK: - Helpers

    private func makeStore(step: RecordFlowFeature.Step.State) -> TestStoreOf<RecordFlowFeature> {
        TestStore(initialState: RecordFlowFeature.State(recordType: .plogging, step: step)) {
            RecordFlowFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.locale = Locale(identifier: "ko_KR")
        }
    }
}
