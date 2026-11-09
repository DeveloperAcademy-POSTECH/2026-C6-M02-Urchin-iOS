//
//  HomeSceneCanvas.swift
//  Plobby
//
//  Created by 더스틴 on 11/8/26.
//

import SwiftUI

/// 피그마 좌표(장면 너비 402) 그대로 장면을 그리고, 실제 화면 너비에 맞춰 통째로 확대/축소해요.
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

/// 장면에 흩어진 쓰레기 하나예요. 도착했을 때의 화면 좌표와 누가 주울지를 가지고 있어요.
struct HomeSceneTrash: Identifiable {
    let id = UUID()
    let image: ImageResource
    /// 그날 장면에 도착했을 때의 화면 좌표(디자인 기준)예요.
    let rect: CGRect
    /// 이 쓰레기를 줍는 사람(다이버)의 번호예요.
    let collector: Int
    var rotation: Double = 0
}

/// 날짜별 쓰레기가 지금 단계에서 어디에, 얼마나 보여야 하는지 정해요.
enum HomeSceneTrashPhase {
    case hidden
    case scattered
    case collecting
    case collected

    init(trashDay: Int, stage: HomeSceneStage) {
        switch stage {
        case .finale:
            self = .collected
        case let .arrived(day):
            self = trashDay < day ? .collected : trashDay == day ? .scattered : .hidden
        case let .collecting(day):
            self = trashDay < day ? .collected : trashDay == day ? .collecting : .hidden
        case let .collected(day):
            self = trashDay <= day ? .collected : .hidden
        }
    }

    var opacity: Double {
        switch self {
        case .scattered, .collecting: 1
        case .hidden, .collected: 0
        }
    }

    var isAtCollector: Bool {
        switch self {
        case .collecting, .collected: true
        case .hidden, .scattered: false
        }
    }
}

extension CGRect {

    /// 중심점을 기준으로 크기를 줄인 사각형이에요.
    func homeSceneShrunk(to scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(width: width * scale, height: height * scale)
        return CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}
