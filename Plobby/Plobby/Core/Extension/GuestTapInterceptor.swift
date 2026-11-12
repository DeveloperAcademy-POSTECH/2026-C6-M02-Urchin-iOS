//
//  GuestTapInterceptor.swift
//  Plobby
//
//  Created by 이은지 on 11/13/26.
//

import MapKit
import SwiftUI

// MARK: - GuestTapInterceptor

/// 창 전체의 탭을 가로채서 원래 동작 대신 `onTap`을 불러요.
/// - 탭바, 지도, 시트·풀스크린처럼 위에 띄운 화면, `guestTapAllowed()`를 붙인 뷰는 가로채지 않아요.
/// - 스크롤·지도 이동·확대 같은 제스처는 그대로 둬요. 탭이 아닌 손동작이 되면 탭 인식이 실패해서 원래 제스처가 이어져요.
struct GuestTapInterceptor: UIViewRepresentable {

    let isEnabled: Bool
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WindowObservingView {
        let view = WindowObservingView()
        view.isUserInteractionEnabled = false
        view.onWindowChanged = { [coordinator = context.coordinator] window in
            coordinator.attach(to: window)
        }
        return view
    }

    func updateUIView(_ view: WindowObservingView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onTap = onTap
    }

    static func dismantleUIView(_ view: WindowObservingView, coordinator: Coordinator) {
        coordinator.attach(to: nil)
    }

    final class WindowObservingView: UIView {

        var onWindowChanged: ((UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            onWindowChanged?(window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var isEnabled = false
        var onTap: () -> Void = {}

        private weak var window: UIWindow?
        private lazy var recognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.delegate = self
            return recognizer
        }()

        func attach(to window: UIWindow?) {
            guard self.window !== window else { return }

            self.window?.removeGestureRecognizer(recognizer)
            self.window = window
            window?.addGestureRecognizer(recognizer)
        }

        @objc private func handleTap() {
            onTap()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard isEnabled,
                  window?.rootViewController?.presentedViewController == nil
            else { return false }

            if let window, GuestTapAllowedFrames.shared.contains(touch.location(in: window)) {
                return false
            }

            var view = touch.view
            while let current = view {
                if current is UITabBar || current is MKMapView { return false }
                view = current.superview
            }
            return true
        }

        /// 버튼 같은 탭은 이 탭이 실패해야 동작해서 원래 동작이 막혀요. 스크롤·확대 제스처는 기다리지 않게 둬요.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            !(otherGestureRecognizer is UIPanGestureRecognizer
              || otherGestureRecognizer is UIPinchGestureRecognizer
              || otherGestureRecognizer is UIRotationGestureRecognizer)
        }
    }
}

// MARK: - Allowed Frames

/// 비회원도 누를 수 있는 뷰의 위치예요. 창 좌표로 들고 있어요.
@MainActor
final class GuestTapAllowedFrames {

    static let shared = GuestTapAllowedFrames()

    private var frames: [UUID: CGRect] = [:]

    func update(_ id: UUID, frame: CGRect?) {
        frames[id] = frame
    }

    func contains(_ point: CGPoint) -> Bool {
        frames.values.contains { $0.contains(point) }
    }
}

private struct GuestTapAllowedModifier: ViewModifier {

    @State private var id = UUID()
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                self.frame = frame
                GuestTapAllowedFrames.shared.update(id, frame: frame)
            }
            .onAppear {
                GuestTapAllowedFrames.shared.update(id, frame: frame)
            }
            .onDisappear {
                GuestTapAllowedFrames.shared.update(id, frame: nil)
            }
    }
}

extension View {

    /// 비회원이 눌러도 로그인 시트 대신 원래 동작을 해요.
    func guestTapAllowed() -> some View {
        modifier(GuestTapAllowedModifier())
    }
}
