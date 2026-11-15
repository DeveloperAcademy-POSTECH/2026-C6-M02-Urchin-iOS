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

    private init() {
        images.totalCostLimit = 100 * 1024 * 1024
    }

    // MARK: - Functions

    func image(for url: URL) -> UIImage? {
        images.object(forKey: url as NSURL)
    }

    /// 사진을 받아 화면에 바로 그릴 수 있게 풀어 둔 뒤 캐시에 넣어요. 메인 스레드를 막지 않게 백그라운드에서 실행해요.
    ///
    /// - Note: 같은 주소를 동시에 요청하면 두 번 받아요. 목록 사진을 다 받기 전에 상세를 여는 일이 잦아지면, 진행 중인 요청을 공유하도록 바꿔 주세요.
    @concurrent
    func load(_ url: URL) async -> UIImage? {
        if let cached = image(for: url) { return cached }

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
