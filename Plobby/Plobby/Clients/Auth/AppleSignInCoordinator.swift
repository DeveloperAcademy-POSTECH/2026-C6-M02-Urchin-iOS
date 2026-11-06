//
//  AppleSignInCoordinator.swift
//  Plobby
//
//  Created by 이은지 on 11/6/26.
//

import AuthenticationServices

final class AppleSignInCoordinator: NSObject {

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

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        finish(.failure(error))
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        if let keyWindow = scenes.compactMap(\.keyWindow).first {
            return keyWindow
        }

        guard let scene = scenes.first else {
            preconditionFailure("Apple 로그인 창을 띄울 WindowScene이 없어요")
        }

        return scene.windows.first ?? ASPresentationAnchor(windowScene: scene)
    }
}
