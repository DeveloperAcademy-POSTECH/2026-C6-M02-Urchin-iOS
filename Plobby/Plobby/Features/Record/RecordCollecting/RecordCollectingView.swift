//
//  RecordCollectingView.swift
//  Plobby
//
//  Created by 이은지 on 11/10/26.
//

import SwiftUI

import ComposableArchitecture

struct RecordCollectingView: View {

    // MARK: - Properties

    let store: StoreOf<RecordCollectingFeature>

    @State private var ringProgress: CGFloat = 0
    @State private var isPlaying = false
    @State private var isCovered = false

    private static let ringDuration: TimeInterval = 1
    private static let coverEndTime: TimeInterval = 1.88

    // MARK: - Body

    var body: some View {
        VStack(spacing: 7.scaled) {
            stage
                .zIndex(1)

            Text("쓰레기를 쏙쏙 담아 모으고 있어요")
                .plobbyFont(.body2)
                .foregroundStyle(Color(.textPrimary))
                .keyframeAnimator(initialValue: 1.0, trigger: isPlaying) { content, opacity in
                    content.opacity(opacity)
                } keyframes: { _ in
                    LinearKeyframe(1, duration: 1.36)
                    LinearKeyframe(0, duration: 0.21, timingCurve: .easeOut)
                    LinearKeyframe(0, duration: 10)
                }
        }
        .padding(.bottom, 342.scaled)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(Color(isCovered ? .neutralBlack : .backgroundDefault).ignoresSafeArea())
        .task {
            withAnimation(.easeInOut(duration: Self.ringDuration)) {
                ringProgress = 1
            }
            try? await Task.sleep(for: .seconds(Self.ringDuration))
            isPlaying = true

            try? await Task.sleep(for: .seconds(Self.coverEndTime))
            isCovered = true
            store.send(.coverFinished)
        }
    }
}

// MARK: - Stage

private extension RecordCollectingView {

    var stage: some View {
        ZStack(alignment: .topLeading) {
            beam
            hole

            ZStack(alignment: .topLeading) {
                ForEach(ThrownTrash.all, id: \.image) { trash in
                    ThrownTrashView(trash: trash, isPlaying: isPlaying)
                }
            }
            .frame(width: 270.scaled, height: 229.scaled, alignment: .topLeading)
            .mask(HoleOpeningMask())
        }
        .frame(width: 270.scaled, height: 229.scaled, alignment: .topLeading)
    }

    var beam: some View {
        Image(.recordCollectingBeam)
            .resizable()
            .frame(width: CGFloat(180.4).scaled, height: CGFloat(128.4).scaled)
            .offset(x: CGFloat(44.8).scaled, y: CGFloat(65.8).scaled)
            .keyframeAnimator(initialValue: 0.0, trigger: isPlaying) { content, opacity in
                content.opacity(opacity)
            } keyframes: { _ in
                LinearKeyframe(0, duration: 0.045)
                LinearKeyframe(1, duration: 0.21, timingCurve: .easeOut)
                LinearKeyframe(1, duration: 1.085)
                LinearKeyframe(0, duration: 0.18, timingCurve: .easeInOut)
                LinearKeyframe(0, duration: 10)
            }
    }

    var hole: some View {
        ZStack {
            // 타원을 다 그리면 안을 검정으로 채워 구멍이 생겨요
            Ellipse()
                .fill(Color(.neutralBlack))
                .opacity(isPlaying ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: isPlaying)

            TopStartEllipse()
                .trim(from: 0, to: ringProgress)
                .stroke(Color(.neutralBlack), style: StrokeStyle(lineWidth: 6.scaled, lineCap: .round))
                .padding(3.scaled)
        }
        .frame(width: 144.scaled, height: 60.scaled)
        .keyframeAnimator(initialValue: 1.0, trigger: isPlaying) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            LinearKeyframe(1, duration: 1.54)
            LinearKeyframe(24, duration: 0.34, timingCurve: .easeInOut)
            LinearKeyframe(24, duration: 10)
        }
        .offset(x: 63.scaled, y: 134.scaled)
    }
}

// MARK: - ThrownTrash

private struct ThrownTrash {
    let image: ImageResource
    let size: CGSize
    let center: CGPoint
    let restingRotation: Double
    let fadeInStart: TimeInterval
    let fadeInEnd: TimeInterval
    let throwStart: TimeInterval
    let shrinkMid: TimeInterval
    let throwEnd: TimeInterval
    let end: TimeInterval
    let dx: CGFloat
    let dy: CGFloat
    let dyEnd: CGFloat
    let spin: Double

    static let all: [ThrownTrash] = [
        ThrownTrash(
            image: .recordCollectingBottle, size: CGSize(width: 26.52, height: 51.43), center: CGPoint(x: 72, y: 80),
            restingRotation: -20.44,
            fadeInStart: 0.035, fadeInEnd: 0.225, throwStart: 0.295, shrinkMid: 0.5126, throwEnd: 0.635, end: 0.755,
            dx: 63, dy: 84, dyEnd: 138, spin: 0.890118
        ),
        ThrownTrash(
            image: .recordCollectingCan, size: CGSize(width: 20.83, height: 29.82), center: CGPoint(x: 141, y: 52),
            restingRotation: 27.68,
            fadeInStart: 0.065, fadeInEnd: 0.246, throwStart: 0.695, shrinkMid: 0.8934, throwEnd: 1.005, end: 1.125,
            dx: -6, dy: 112, dyEnd: 166, spin: -0.872665
        ),
        ThrownTrash(
            image: .recordCollectingBag, size: CGSize(width: 22.11, height: 23.1), center: CGPoint(x: 201, y: 88),
            restingRotation: 44,
            fadeInStart: 0.095, fadeInEnd: 0.27, throwStart: 1.065, shrinkMid: 1.257, throwEnd: 1.365, end: 1.485,
            dx: -66, dy: 76, dyEnd: 130, spin: -0.837758
        )
    ]
}

private struct ThrownTrashView: View {

    let trash: ThrownTrash
    let isPlaying: Bool

    private struct Values {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var scale: CGFloat = 1
        var spin: Double = 0
        var opacity: Double = 0
    }

    private static let throwCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.53, y: 0.04),
        endControlPoint: UnitPoint(x: 0.8, y: 0.43)
    )

    var body: some View {
        let t = trash
        let ratio = CGFloat(1).scaled

        Image(t.image)
            .resizable()
            .frame(width: t.size.width.scaled, height: t.size.height.scaled)
            .rotationEffect(.degrees(t.restingRotation))
            .keyframeAnimator(initialValue: Values(), trigger: isPlaying) { content, value in
                content
                    .rotationEffect(.radians(value.spin))
                    .scaleEffect(value.scale)
                    .offset(x: value.x * ratio, y: value.y * ratio)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0, duration: t.fadeInStart)
                    LinearKeyframe(1, duration: t.fadeInEnd - t.fadeInStart, timingCurve: .easeOut)
                    LinearKeyframe(1, duration: t.end - t.fadeInEnd)
                    LinearKeyframe(0, duration: 0.01)
                    LinearKeyframe(0, duration: 10)
                }
                KeyframeTrack(\.x) {
                    LinearKeyframe(0, duration: t.throwStart)
                    LinearKeyframe(t.dx, duration: t.throwEnd - t.throwStart, timingCurve: Self.throwCurve)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(0, duration: t.throwStart)
                    LinearKeyframe(t.dy, duration: t.throwEnd - t.throwStart, timingCurve: Self.throwCurve)
                    LinearKeyframe(t.dyEnd, duration: t.end - t.throwEnd)
                }
                KeyframeTrack(\.spin) {
                    LinearKeyframe(0, duration: t.throwStart)
                    LinearKeyframe(t.spin, duration: t.throwEnd - t.throwStart, timingCurve: Self.throwCurve)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(0.6, duration: t.fadeInStart)
                    SpringKeyframe(1, duration: t.throwStart - t.fadeInStart, spring: .bouncy)
                    LinearKeyframe(0.82, duration: t.shrinkMid - t.throwStart, timingCurve: .easeInOut)
                    LinearKeyframe(0.65, duration: t.throwEnd - t.shrinkMid)
                    LinearKeyframe(0.55, duration: t.end - t.throwEnd)
                }
            }
            .position(x: t.center.x.scaled, y: t.center.y.scaled)
    }
}

// MARK: - HoleOpeningMask

private struct HoleOpeningMask: Shape {

    func path(in rect: CGRect) -> Path {
        let ratio = rect.width / 270

        // 구멍(63, 134, 144x60)
        let opening = CGRect(x: 63, y: 134, width: 144, height: 60)
        let scaled = CGRect(x: opening.minX * ratio, y: opening.minY * ratio, width: opening.width * ratio, height: opening.height * ratio)

        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: scaled.midY))
            path.addLine(to: CGPoint(x: scaled.maxX, y: scaled.midY))
            path.addArc(
                center: .zero,
                radius: 1,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false,
                transform: CGAffineTransform(translationX: scaled.midX, y: scaled.midY)
                    .scaledBy(x: scaled.width / 2, y: scaled.height / 2)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: scaled.midY))
            path.closeSubpath()
        }
    }
}

// MARK: - TopStartEllipse

private struct TopStartEllipse: Shape {

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(
                center: .zero,
                radius: 1,
                startAngle: .degrees(-90),
                endAngle: .degrees(270),
                clockwise: false
            )
        }
        .applying(
            CGAffineTransform(translationX: rect.midX, y: rect.midY)
                .scaledBy(x: rect.width / 2, y: rect.height / 2)
        )
    }
}
