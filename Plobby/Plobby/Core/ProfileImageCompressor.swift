//
//  ProfileImageCompressor.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import UIKit

nonisolated enum ProfileImageCompressor {
    
    private static let maximumDimension: CGFloat = 1024
    private static let compressionQuality: CGFloat = 0.8
    static let maximumByteCount = 2 * 1024 * 1024
    
    static func compressedJPEG(
        from data: Data,
        maximumByteCount: Int = maximumByteCount
    ) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let scale = min(1, maximumDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rect = CGRect(origin: .zero, size: size)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let jpegData = UIGraphicsImageRenderer(size: size, format: format)
            .jpegData(withCompressionQuality: compressionQuality) { context in
                UIColor.white.setFill()
                context.fill(rect)
                image.draw(in: rect)
            }

        return jpegData.count < maximumByteCount ? jpegData : nil
    }
}
