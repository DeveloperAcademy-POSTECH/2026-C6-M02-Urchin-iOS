//
//  CachedImage.swift
//  Plobby
//
//  Created by 이은지 on 11/15/26.
//

import SwiftUI
import UIKit

/// 한 번 받은 사진을 메모리에 저장해 두고 다시 쓰는 이미지 뷰예요. 쓰는 법은 `AsyncImage`와 같아요.
///
/// `AsyncImage`로는 목록에서 받은 사진을 상세 화면에서 다시 받는 일이 있었어요.
/// 서버에서 받아 오는 사진(기록 사진, 프로필 사진)은 `AsyncImage` 대신 이 뷰를 써 주세요.
///
/// ```swift
/// CachedImage(url: record.coverPhotoURL) { image in
///     image.resizable().scaledToFill()
/// } placeholder: {
///     Color(.gray50)
/// }
/// ```
struct CachedImage<Content: View, Placeholder: View>: View {

    // MARK: - Properties

    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    /// 받아 온 사진과 그 주소예요. 셀이 재사용되어 `url`이 바뀌었을 때 이전 사진이 보이지 않게 함께 기억해요.
    @State private var loadedImage: UIImage?
    @State private var loadedURL: URL?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let image = displayedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url, ImageCache.shared.image(for: url) == nil else { return }

            let image = await ImageLoader.shared.load(url)
            guard !Task.isCancelled else { return }

            loadedImage = image
            loadedURL = url
        }
    }

    /// 캐시는 `body`에서 바로 확인해요. `.task`는 첫 프레임 뒤에 실행돼서, 거기서만 확인하면 캐시에 있어도 회색 칸이 한 번 깜빡여요.
    private var displayedImage: UIImage? {
        guard let url else { return nil }

        return ImageCache.shared.image(for: url) ?? (loadedURL == url ? loadedImage : nil)
    }
}
