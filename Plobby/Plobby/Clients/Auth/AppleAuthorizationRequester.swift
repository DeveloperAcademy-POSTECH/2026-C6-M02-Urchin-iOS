//
//  AppleAuthorizationRequester.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import AuthenticationServices
import UIKit

final class AppleAuthorizationRequester: NSObject {

    private let anchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<String, any Error>?
    private var controller: ASAuthorizationController?
    private var retainedSelf: AppleAuthorizationRequester?

    private init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    @MainActor
    static func fetchAuthorizationCode() async throws -> String {
        guard let anchor = currentAnchor() else {
            throw AppleSignInError.failed
        }

        return try await AppleAuthorizationRequester(anchor: anchor).presentAppleSignIn()
    }

    @MainActor
    private static func currentAnchor() -> ASPresentationAnchor? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        if let keyWindow = windowScenes.lazy.compactMap(\.keyWindow).first {
            return keyWindow
        }

        return windowScenes.first.map { ASPresentationAnchor(windowScene: $0) }
    }

    private func presentAppleSignIn() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.retainedSelf = self

            let request = ASAuthorizationAppleIDProvider().createRequest()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<String, any Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
        retainedSelf = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthorizationRequester: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let codeData = credential.authorizationCode,
            let code = String(data: codeData, encoding: .utf8)
        else {
            finish(.failure(AppleSignInError.failed))
            return
        }

        finish(.success(code))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        finish(.failure(AppleSignInError(error)))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleAuthorizationRequester: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        anchor
    }
}
