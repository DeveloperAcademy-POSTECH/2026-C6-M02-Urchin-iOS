//
//  AppleAuthClient.swift
//  Plobby
//
//  Created by dlsundn on 11/6/26.
//

import AuthenticationServices
import UIKit

import Dependencies

/// Apple 로그인 창을 코드로 띄워 인증 정보를 받아와요.
/// 회원탈퇴처럼 Apple 버튼 없이 재인증이 필요할 때 써요.
struct AppleAuthClient {
    /// Apple 재인증 후 `authorizationCode`를 돌려줘요. 사용자가 취소하면 `AppleSignInError.canceled`를 던져요.
    var fetchAuthorizationCode: @Sendable () async throws -> String
}

extension AppleAuthClient: DependencyKey {
    static let liveValue: AppleAuthClient = {
        .init(
            fetchAuthorizationCode: {
                try await AppleAuthorizationRequester().fetchAuthorizationCode()
            }
        )
    }()
}

// MARK: - AppleAuthorizationRequester

private final class AppleAuthorizationRequester: NSObject {

    private var continuation: CheckedContinuation<String, any Error>?
    private var controller: ASAuthorizationController?
    /// Apple 창은 delegate를 weak으로 들고 있어서, 결과가 올 때까지 스스로를 붙잡아 둬요.
    private var retainedSelf: AppleAuthorizationRequester?

    func fetchAuthorizationCode() async throws -> String {
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
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        if let keyWindow = windowScenes.lazy.compactMap(\.keyWindow).first {
            return keyWindow
        }

        guard let windowScene = windowScenes.first else {
            fatalError("Apple 로그인 창을 띄울 화면이 없어요")
        }

        return ASPresentationAnchor(windowScene: windowScene)
    }
}
