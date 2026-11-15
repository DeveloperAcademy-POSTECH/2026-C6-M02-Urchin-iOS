//
//  ImageCache.swift
//  Plobby
//
//  Created by 이은지 on 11/15/26.
//

import UIKit

/// 사진 주소를 키로 받은 사진을 메모리에 저장해요. 앱 전체가 `shared` 하나를 함께 써요.
///
/// `NSCache`는 메모리가 부족하면 시스템이 알아서 비우고, 여러 스레드에서 동시에 써도 안전해요.
nonisolated final class ImageCache: @unchecked Sendable {

    // MARK: - Properties

    static let shared = ImageCache()

    private let images = NSCache<NSURL, UIImage>()

    /// 받는 중인 사진이에요. 같은 주소를 또 요청하면 새로 받지 않고 이 작업을 함께 기다려요.
    private var downloads: [URL: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()

    private init() {
        images.totalCostLimit = 100 * 1024 * 1024
    }

    // MARK: - Functions

    func image(for url: URL) -> UIImage? {
        images.object(forKey: url as NSURL)
    }

    /// 캐시에 없으면 사진을 받아서 캐시에 넣고 돌려줘요.
    ///
    /// 다운로드는 화면과 상관없이 끝까지 진행해요. 느린 네트워크에서 다 받기 전에 화면을 나가도 취소되지 않아서,
    /// 다음에 들어오면 그사이 받아 둔 사진을 바로 써요.
    func load(_ url: URL) async -> UIImage? {
        if let cached = image(for: url) { return cached }

        let download = lock.withLock {
            if let download = downloads[url] { return download }

            let download = Task.detached(priority: .userInitiated) { [self] in
                await fetchImage(from: url)
            }
            downloads[url] = download
            return download
        }

        return await download.value
    }

    /// 사진을 받아 화면에 바로 그릴 수 있게 풀어 둔 뒤 캐시에 넣어요. 메인 스레드 밖에서 실행돼요.
    private func fetchImage(from url: URL) async -> UIImage? {
        defer { lock.withLock { downloads[url] = nil } }

        guard
            let data = try? await URLSession.shared.data(from: url).0,
            let image = await UIImage(data: data)?.byPreparingForDisplay()
        else { return nil }

        // 파일 크기보다 실제로 메모리에 풀린 크기가 훨씬 커서, 픽셀 메모리 크기로 용량 상한(100MB)을 계산해요.
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? data.count
        images.setObject(image, forKey: url as NSURL, cost: cost)
        return image
    }
}
