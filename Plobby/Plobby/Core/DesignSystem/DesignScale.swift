//
//  DesignScale.swift
//  Plobby
//
//  Created by 이은지 on 11/2/26.
//

import UIKit

/// Figma 시안 크기와 실제 화면 크기를 비교해 에셋에 곱할 배율을 계산합니다.
/// - frameWidth: Figma 기준 프레임의 폭
/// - frameHeight: Figma 기준 프레임의 높이
/// - fitRatio(for:): 폭과 높이 비율 중 작은 값을 반환해 이미지 비율을 유지한 채 화면에 맞춤
/// - ratio: 시안 폭 대비 화면 폭 배율. 고정 크기에 `.scaled`로 곱하면 어떤 기기에서도 같은 비율로 보입니다.
///
enum DesignScale {
    
    static let frameWidth: CGFloat = 402
    static let frameHeight: CGFloat = 874
    
    static let ratio: CGFloat = {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let width = scene?.screen.bounds.width ?? frameWidth
        return width / frameWidth
    }()
    
    static func fitRatio(for size: CGSize) -> CGFloat {
        min(size.width / frameWidth, size.height / frameHeight)
    }
}

extension CGFloat {

    var scaled: CGFloat { self * DesignScale.ratio }
}

extension Int {

    var scaled: CGFloat { CGFloat(self) * DesignScale.ratio }
}
