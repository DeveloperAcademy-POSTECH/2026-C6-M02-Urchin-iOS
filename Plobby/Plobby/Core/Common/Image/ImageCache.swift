//
//  ImageCache.swift
//  Plobby
//
//  Created by 이은지 on 11/15/26.
//

import UIKit

/// 사진 주소를 키로 받은 사진을 메모리에 저장해요. 앱 전체가 `shared` 하나를 함께 써요.
///
/// `CachedImage`가 `body`에서 바로(동기로) 꺼내 쓸 수 있어야 해서 actor로 만들지 않았어요.
/// `NSCache`는 여러 스레드에서 동시에 써도 안전하고, 메모리가 부족하면 시스템이 알아서 비워요.
/// 사진을 받는 일은 `ImageLoader`가 맡아요.
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

    /// 파일 크기보다 실제로 메모리에 풀린 크기가 훨씬 커서, 픽셀 메모리 크기로 용량 상한(100MB)을 계산해요.
    func insert(_ image: UIImage, for url: URL, fileSize: Int) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? fileSize
        images.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
