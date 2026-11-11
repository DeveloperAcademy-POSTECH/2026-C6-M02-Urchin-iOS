//
//  NicknameCheckView.swift
//  Plobby
//
//  Created by dlsundn on 11/10/26.
//

import SwiftUI

import ComposableArchitecture

/// "닉네임" 제목, 입력창 안의 중복 확인 버튼, 아래 안내 문구예요.
/// 알림창은 화면 전체를 덮어야 해서, 쓰는 화면에서 `store.alert`로 띄워요.
struct NicknameCheckView: View {

    // MARK: - Properties

    @Bindable var store: StoreOf<NicknameCheckFeature>
    var isFocused: FocusState<Bool>.Binding
    /// 확인을 마쳤을 때 "사용 가능한 닉네임이에요"를 보여줄지예요.
    var showsAvailableMessage = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("닉네임")
                .plobbyFont(.cardTitle)
                .foregroundStyle(Color(.textPrimary))

            nicknameField
                .padding(.top, 12.scaled)

            if let message {
                Text(message.text)
                    .plobbyFont(.helper)
                    .foregroundStyle(message.isError ? Color(.currentError) : Color(.textBrand))
                    .padding(.top, 6.scaled)
            }
        }
    }
}

// MARK: - 입력창

extension NicknameCheckView {

    private var nicknameField: some View {
        HStack(alignment: .center, spacing: 8.scaled) {
            TextField(
                "",
                text: $store.nickname,
                prompt: Text("닉네임 입력")
                    .foregroundStyle(Color(.textSecondary))
            )
            .focused(isFocused)
            .plobbyFont(.body)
            .foregroundStyle(Color(.textPrimary))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)

            checkButton
        }
        .padding(.horizontal, 12.scaled)
        .frame(height: 51.scaled)
        .background(Color(.backgroundDefault), in: RoundedRectangle(cornerRadius: 8.scaled))
        .overlay {
            RoundedRectangle(cornerRadius: 8.scaled)
                .strokeBorder(store.hasError ? Color(.currentError) : Color(.borderDefault), lineWidth: 1)
        }
    }

    /// 확인을 마치면 회색 배경에 초록 "확인 완료"로 바뀌고, 확인할 수 없을 때는 흐리게 보여줘요.
    /// `.disabled`는 글자를 자동으로 흐리게 해서, 색은 직접 정하고 터치만 막아요.
    private var checkButton: some View {
        Button {
            store.send(.checkButtonTapped)
        } label: {
            Text(store.isChecked ? "확인 완료" : "중복 확인")
                .plobbyFont(.label)
                .foregroundStyle(store.canCheck || store.isChecked ? Color(.textBrand) : Color(.textDisabled))
                .padding(.horizontal, 18.scaled)
                .frame(height: 40.scaled)
                .background(
                    store.canCheck ? Color(.brandPrimarySubtle) : Color(.surfaceSubtle),
                    in: RoundedRectangle(cornerRadius: 8.scaled)
                )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(store.canCheck)
    }
}

// MARK: - 안내 문구

extension NicknameCheckView {

    private var message: (text: String, isError: Bool)? {
        if store.isFormatInvalid || store.isOverLimit {
            return ("한글, 영문, 숫자로 \(Nickname.minimumLength)~\(Nickname.maximumLength)자 입력해주세요.", true)
        }
        if store.isAvailable == false {
            return ("이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해 주세요", true)
        }
        if store.isChecked && showsAvailableMessage {
            return ("사용 가능한 닉네임이에요", false)
        }
        return nil
    }
}
