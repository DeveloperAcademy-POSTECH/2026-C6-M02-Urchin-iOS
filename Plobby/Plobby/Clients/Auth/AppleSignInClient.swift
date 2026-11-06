//
//  AppleSignInClient.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import AuthenticationServices

import Dependencies

/// 버튼 뷰 없이 Feature에서 Apple 로그인 창을 띄울 때 사용해요 (띄운 화면이 사라져도 결과를 받을 수 있어요)
struct AppleSignInClient {
    var fetchCredential: @Sendable (_ hashedNonce: String) async -> Result<AppleCredential, AppleSignInError>
}

extension AppleSignInClient: DependencyKey {
    static let liveValue = AppleSignInClient(
        fetchCredential: { hashedNonce in
            await AppleSignInCoordinator.fetchCredential(hashedNonce: hashedNonce)
        }
    )
}

extension DependencyValues {

    nonisolated var appleSignInClient: AppleSignInClient {
        get { self[AppleSignInClient.self] }
        set { self[AppleSignInClient.self] = newValue }
    }
}

// MARK: - Coordinator

private final class AppleSignInCoordinator: NSObject {

    private var continuation: CheckedContinuation<Result<ASAuthorization, any Error>, Never>?

    static func fetchCredential(hashedNonce: String) async -> Result<AppleCredential, AppleSignInError> {
        let coordinator = AppleSignInCoordinator()

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator

        let result = await withCheckedContinuation { continuation in
            coordinator.continuation = continuation
            controller.performRequests()
        }

        return result.appleCredential
    }

    private func finish(_ result: Result<ASAuthorization, any Error>) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        finish(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        finish(.failure(error))
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}
