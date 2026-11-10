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
    @State private var beamProgress: CGFloat = 0
    @State private var thrownCount = 0

    private static let ringSize = CGSize(width: 144, height: 46)
    private static let ringDuration: TimeInterval = 1
    private static let beamDuration: TimeInterval = 0.6
    private static let throwInterval: TimeInterval = 0.35

    private static let thrownTrash: [ThrownTrash] = [
        ThrownTrash(image: .bottleBlueM, height: 44, start: CGSize(width: -56, height: -150), rotation: -30),
        ThrownTrash(image: .batteryOrangeM, height: 34, start: CGSize(width: 24, height: -170), rotation: 25),
        ThrownTrash(image: .plasticBagPinkM, height: 30, start: CGSize(width: 68, height: -130), rotation: -20)
    ]

    // MARK: - Body

    var body: some View { 
        VStack(spacing: 48.scaled) {
            ring

            Text("쓰레기를 쏙쏙 담아 모으고 있어요")
                .plobbyFont(.body2)
                .foregroundStyle(Color(.textPrimary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.backgroundDefault))
        .onAppear {
            store.send(.onAppear)

            withAnimation(.easeInOut(duration: Self.ringDuration)) {
                ringProgress = 1
            }
            withAnimation(.easeOut(duration: Self.beamDuration).delay(Self.ringDuration)) {
                beamProgress = 1
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(Self.ringDuration + Self.beamDuration))
            for _ in Self.thrownTrash {
                thrownCount += 1
                try? await Task.sleep(for: .seconds(Self.throwInterval))
            }
        }
    }
}

// MARK: - Subviews

private extension RecordCollectingView {

    var ring: some View {
        TopStartEllipse()
            .trim(from: 0, to: ringProgress)
            .stroke(Color(.textPrimary), style: StrokeStyle(lineWidth: 6.scaled, lineCap: .round))
            .frame(width: Self.ringSize.width.scaled, height: Self.ringSize.height.scaled)
            .background(alignment: .bottom) {
                beam
            }
            .overlay {
                ForEach(Array(Self.thrownTrash.enumerated()), id: \.offset) { index, trash in
                    ThrownTrashView(trash: trash, isThrown: index < thrownCount)
                }
            }
    }

    var beam: some View {
        BeamShape(ellipseSize: CGSize(width: Self.ringSize.width.scaled, height: Self.ringSize.height.scaled))
            .fill(
                LinearGradient(
                    colors: [Color(.neutralBlack).opacity(0.85), Color(.neutralBlack).opacity(0)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 180.scaled, height: 120.scaled)
            .scaleEffect(x: 1, y: beamProgress, anchor: .bottom)
            .opacity(beamProgress)
    }
}

// MARK: - ThrownTrash

private struct ThrownTrash {
    let image: ImageResource
    let height: CGFloat
    let start: CGSize
    let rotation: Double
}

private struct ThrownTrashView: View {

    let trash: ThrownTrash
    let isThrown: Bool

    private struct Values {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var scale: CGFloat = 1
        var rotation: Double = 0
        var opacity: Double = 0
    }

    private static let duration: TimeInterval = 0.55

    var body: some View {
        Image(trash.image)
            .resizable()
            .scaledToFit()
            .frame(height: trash.height.scaled)
            .keyframeAnimator(initialValue: Values(), trigger: isThrown) { content, value in
                content
                    .rotationEffect(.degrees(value.rotation))
                    .scaleEffect(value.scale)
                    .offset(x: value.x, y: value.y)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    LinearKeyframe(trash.start.width.scaled, duration: 0)
                    LinearKeyframe(0, duration: Self.duration)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(trash.start.height.scaled, duration: 0)
                    CubicKeyframe(0, duration: Self.duration, startVelocity: -200)
                }
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(trash.rotation, duration: 0)
                    LinearKeyframe(trash.rotation + 180, duration: Self.duration)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1, duration: Self.duration * 0.6)
                    CubicKeyframe(0.3, duration: Self.duration * 0.4)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.05)
                    LinearKeyframe(1, duration: Self.duration * 0.75)
                    LinearKeyframe(0, duration: Self.duration * 0.25 - 0.05)
                }
            }
    }
}

// MARK: - BeamShape

private struct BeamShape: Shape {

    let ellipseSize: CGSize

    func path(in rect: CGRect) -> Path {
        let ellipseCenter = CGPoint(x: rect.midX, y: rect.maxY - ellipseSize.height / 2)

        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: ellipseCenter.x + ellipseSize.width / 2, y: ellipseCenter.y))
            path.addArc(
                center: .zero,
                radius: 1,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false,
                transform: CGAffineTransform(translationX: ellipseCenter.x, y: ellipseCenter.y)
                    .scaledBy(x: ellipseSize.width / 2, y: ellipseSize.height / 2)
            )
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
