//
//  HomeSceneCanvas.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeSceneCanvas<Content: View>: View {

    static var designWidth: CGFloat { 402 }

    @ViewBuilder let content: (_ designHeight: CGFloat) -> Content

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Self.designWidth
            let designHeight = proxy.size.height / max(scale, 0.01)

            ZStack(alignment: .topLeading) {
                content(designHeight)
            }
            .frame(width: Self.designWidth, height: designHeight, alignment: .topLeading)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .clipped()
    }
}

extension CGRect {

    /// 중심점을 기준으로 크기를 줄인 사각형이에요.
    func homeSceneShrunk(to scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(width: width * scale, height: height * scale)
        return CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}
