//
//  HomeSceneCanvas.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

struct HomeSceneCanvas<Content: View>: View {

    static var designWidth: CGFloat { 402 }
    private static var topOverflow: CGFloat { 1000 }

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
        .mask {
            Rectangle()
                .padding(.top, -Self.topOverflow)
        }
    }
}

struct HomeSceneBackdrop: View {

    let image: ImageResource

    var body: some View {
        if let strip = Self.topStrip(of: image) {
            Image(uiImage: strip)
                .resizable()
        } else {
            Color(.gray0)
        }
    }

    private static func topStrip(of resource: ImageResource) -> UIImage? {
        let image = UIImage(resource: resource)
        guard let cgImage = image.cgImage,
              let row = cgImage.cropping(to: CGRect(x: 0, y: 0, width: cgImage.width, height: 1))
        else { return nil }

        return UIImage(cgImage: row, scale: image.scale, orientation: image.imageOrientation)
    }
}

struct HomeWalkPath {

    static let walkAnimation: Animation = .interactiveSpring(response: 0.18, dampingFraction: 0.86)
    static let cameraAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.9)
    private static let minimumDragLength: CGFloat = 80
    
    let nodes: [CGFloat]

    func offset(at progress: Double) -> CGFloat {
        let position = min(max(progress + 1, 0), Double(nodes.count - 1))
        let index = min(Int(position), nodes.count - 2)
        let fraction = CGFloat(position - Double(index))
        return nodes[index] + (nodes[index + 1] - nodes[index]) * fraction
    }

    func progress(from start: Double, moving distance: CGFloat) -> Double {
        let last = Double(nodes.count - 1)
        var position = min(max(start + 1, 0), last)
        var remaining = distance

        while abs(remaining) > 0.01 {
            if remaining > 0 {
                guard position < last else { break }
                
                let index = Int(position.rounded(.down))
                let length = segmentLength(index)
                let available = (Double(index + 1) - position) * length
                guard remaining < available else {
                    position = Double(index + 1)
                    remaining -= available
                    continue
                }
                
                position += remaining / length
                remaining = 0
            } else {
                guard position > 0 else { break }
                
                let index = Int(position.rounded(.up)) - 1
                let length = segmentLength(index)
                let available = (position - Double(index)) * length
                guard -remaining < available else {
                    position = Double(index)
                    remaining += available
                    continue
                }
                
                position += remaining / length
                remaining = 0
            }
        }
        return position - 1
    }

    private func segmentLength(_ index: Int) -> CGFloat {
        max(abs(nodes[index + 1] - nodes[index]), Self.minimumDragLength)
    }
}

extension CGRect {

    func homeSceneShrunk(to scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(width: width * scale, height: height * scale)
        return CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
