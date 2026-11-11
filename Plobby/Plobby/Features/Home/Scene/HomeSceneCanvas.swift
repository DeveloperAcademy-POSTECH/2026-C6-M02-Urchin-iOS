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

/// 사람이 해변 위를 걸어가는 길이에요.
/// 진행도 -1은 해변 시작, 0부터 lastDay까지는 각 날짜, lastDay + 1은 마지막 도착점(수거대·배)이에요.
struct HomeWalkPath {

    /// 진행도 -1부터 1씩 늘어나는 지점마다 화면이 내려가야 하는 거리예요.
    let nodes: [CGFloat]

    /// 사람은 손가락을 바로 따라가요.
    static let walkAnimation: Animation = .interactiveSpring(response: 0.18, dampingFraction: 0.86)

    /// 화면은 사람보다 느리게 따라가서, 게임 캐릭터를 따라가는 카메라처럼 보여요.
    static let cameraAnimation: Animation = .spring(response: 0.55, dampingFraction: 0.9)

    /// 거의 움직이지 않는 구간도 이만큼은 끌어야 지나가요.
    private static let minimumDragLength: CGFloat = 80

    func offset(at progress: Double) -> CGFloat {
        let position = min(max(progress + 1, 0), Double(nodes.count - 1))
        let index = min(Int(position), nodes.count - 2)
        let fraction = CGFloat(position - Double(index))
        return nodes[index] + (nodes[index + 1] - nodes[index]) * fraction
    }

    /// 손가락으로 끈 거리만큼 길을 따라 걸어간 뒤의 진행도예요. 앞(아래)으로 가면 distance가 양수예요.
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

    /// 중심점을 기준으로 크기를 줄인 사각형이에요.
    func homeSceneShrunk(to scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(width: width * scale, height: height * scale)
        return CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}
