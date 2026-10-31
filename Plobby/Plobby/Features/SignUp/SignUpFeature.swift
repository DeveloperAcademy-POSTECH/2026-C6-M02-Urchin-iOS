//
//  SignUpFeature.swift
//  Plobby
//
//  Created by 이은지 on 10/31/26.
//

import Foundation

import ComposableArchitecture

@Reducer
struct SignUpFeature {
    
    // MARK: - Path
    
    @Reducer
    enum Path {
        case region(RegionFeature)
        case complete(CompleteFeature)
    }

    // MARK: - State
    
    @ObservableState
    struct State: Equatable {
        let user: AuthUser
        var fullName: String?
        var profileImage: Data?
        var nickname = ""
        var isCheckingNickname = false
        var isNicknameAvailable: Bool?
        var path = StackState<Path.State>()
        @Presents var alert: AlertState<Action.Alert>?
        
        var canCheckNickname: Bool {
            Nickname.isValid(nickname) && !isCheckingNickname
        }
    }

    // MARK: - Action
    
    enum Action {
        case profileImageSelected(Data)
        case profileImageCompressed(Data?)
        case alert(PresentationAction<Alert>)
        case nicknameChanged(String)
        case nicknameCheckButtonTapped
        case nicknameCheckResponse(Result<Bool, any Error>)
        case nextButtonTapped
        case path(StackActionOf<Path>)
        
        enum Alert {
            case confirm
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.authClient) var authClient

    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .profileImageSelected(data):
                return compressProfileImage(data)
                
            case let .profileImageCompressed(data):
                guard let data else {
                    state.alert = .make(.profileImageTooLarge)
                    return .none
                }

                state.profileImage = data
                return .none
                
            case let .nicknameChanged(nickname):
                state.nickname = nickname
                state.isCheckingNickname = false
                state.isNicknameAvailable = nil
                return .cancel(id: CancelID.nicknameCheck)
                
            case .nicknameCheckButtonTapped:
                guard state.canCheckNickname else { return .none }
                
                state.isCheckingNickname = true
                
                return checkNickname(state.nickname)
                
            case let .nicknameCheckResponse(.success(isAvailable)):
                state.isCheckingNickname = false
                state.isNicknameAvailable = isAvailable
                return .none
                
            case .nicknameCheckResponse(.failure):
                state.isCheckingNickname = false
                return .none
                
            case .nextButtonTapped:
                state.path.append(.region(RegionFeature.State()))
                return .none

            case .path(.element(id: _, action: .region(.nextButtonTapped))):
                state.path.append(.complete(CompleteFeature.State()))
                return .none

            case .path, .alert:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Functions

extension SignUpFeature {
    
    private nonisolated enum CancelID {
        case nicknameCheck
    }
    
    private func compressProfileImage(_ data: Data) -> Effect<Action> {
        .run { send in
            await send(.profileImageCompressed(
                ProfileImageCompressor.compressedJPEG(from: data)
            ))
        }
    }
    
    private func checkNickname(_ nickname: String) -> Effect<Action> {
        .run { send in
            await send(.nicknameCheckResponse(Result {
                try await authClient.fetchIsNicknameAvailable(nickname)
            }))
        }
        .cancellable(id: CancelID.nicknameCheck, cancelInFlight: true)
    }
}

// MARK: - Conformance

extension SignUpFeature.Path.State: Equatable {}
