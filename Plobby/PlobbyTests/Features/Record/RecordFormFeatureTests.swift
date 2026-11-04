//
//  RecordFormFeatureTests.swift
//  PlobbyTests
//
//  Created by 더스틴 on 11/5/26.
//

import Foundation
import Testing

import ComposableArchitecture
@testable import Plobby

@MainActor
struct RecordFormFeatureTests {

    private let photos = ["a", "b", "c"].map { PhotoAsset(id: $0) }

    // MARK: - 활동 사진

    @Test
    func 뒤의_사진을_맨_앞으로_옮기면_대표사진이_된다() async {
        let store = makeStore()

        await store.send(.photoMoved("c", to: "a")) {
            $0.photos = [self.photos[2], self.photos[0], self.photos[1]]
        }
    }

    @Test
    func 앞의_사진을_뒤로_옮긴다() async {
        let store = makeStore()

        await store.send(.photoMoved("a", to: "c")) {
            $0.photos = [self.photos[1], self.photos[2], self.photos[0]]
        }
    }

    @Test
    func 같은_자리에_놓으면_순서가_바뀌지_않는다() async {
        let store = makeStore()

        await store.send(.photoMoved("b", to: "b"))
    }

    @Test
    func 삭제_버튼을_누르면_사진이_빠지고_뒤_사진이_당겨진다() async {
        let store = makeStore()

        await store.send(.photoDeleteTapped("a")) {
            $0.photos = [self.photos[1], self.photos[2]]
        }
    }

    // MARK: - Helpers

    private func makeStore() -> TestStoreOf<RecordFormFeature> {
        var state = RecordFormFeature.State(recordType: .plogging)
        state.photos = IdentifiedArray(uniqueElements: photos)

        return TestStore(initialState: state) {
            RecordFormFeature()
        }
    }
}
