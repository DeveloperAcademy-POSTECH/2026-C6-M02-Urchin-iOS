//
//  ImageLoader.swift
//  Plobby
//
//  Created by 이은지 on 11/16/26.
//

import UIKit

/// 사진을 받아서 `ImageCache`에 넣어요. 받는 중인 다운로드를 actor가 관리해서, 같은 주소는 한 번만 받아요.
actor ImageLoader {

    // MARK: - Properties

    static let shared = ImageLoader()

    /// 받는 중인 사진이에요. 같은 주소를 또 요청하면 새로 받지 않고 이 작업을 함께 기다려요.
    private var downloads: [URL: Task<UIImage?, Never>] = [:]

    // MARK: - Functions

    /// 캐시에 없으면 사진을 받아서 캐시에 넣고 돌려줘요.
    ///
    /// 다운로드는 화면과 상관없이 끝까지 진행해요. 느린 네트워크에서 다 받기 전에 화면을 나가도 취소되지 않아서,
    /// 다음에 들어오면 그사이 받아 둔 사진을 바로 써요.
    func load(_ url: URL) async -> UIImage? {
        if let cached = ImageCache.shared.image(for: url) { return cached }
        if let download = downloads[url] { return await download.value }

        // 확인과 등록 사이에 await가 없어야 같은 주소를 동시에 요청해도 한 번만 받아요. 이 사이에 await를 넣지 마세요.
        let download = Task.detached(priority: .userInitiated) {
            await Self.fetchImage(from: url)
        }
        downloads[url] = download

        let image = await download.value
        downloads[url] = nil
        return image
    }

    /// 사진을 받아 화면에 바로 그릴 수 있게 풀어 둔 뒤 캐시에 넣어요. actor 밖, 메인 스레드 밖에서 실행돼요.
    @concurrent
    private static func fetchImage(from url: URL) async -> UIImage? {
        guard
            let data = try? await URLSession.shared.data(from: url).0,
            let image = await UIImage(data: data)?.byPreparingForDisplay()
        else { return nil }

        ImageCache.shared.insert(image, for: url, fileSize: data.count)
        return image
    }
}
