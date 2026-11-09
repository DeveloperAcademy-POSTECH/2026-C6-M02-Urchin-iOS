//
//  TermsAgreementView.swift
//  Plobby
//
//  Created by 이은지 on 11/7/26.
//

import SwiftUI

import ComposableArchitecture

struct TermsAgreementView: View {

    // MARK: - Properties

    let store: StoreOf<SignUpFeature>
    @Environment(\.openURL) private var openURL

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            allAgreementRow

            Divider()
                .foregroundStyle(Color(.borderSubtle))
                .padding(.bottom, 12.scaled)

            agreementRow(
                "만 14세 이상입니다",
                isChecked: store.isAgeConfirmed,
                action: .ageConfirmationTapped
            )

            agreementRow(
                "서비스 이용약관 동의",
                isChecked: store.isTermsAgreed,
                action: .termsAgreementTapped,
                detailLink: .termsOfService
            )

            agreementRow(
                "개인정보 수집·이용 동의",
                isChecked: store.isPrivacyAgreed,
                action: .privacyAgreementTapped,
                detailLink: .privacyPolicy
            )

            Spacer()

            PlobbyButton(text: "다음") {
                store.send(.agreementNextButtonTapped)
            }
            .disabled(!store.isAllAgreed)
        }
        .padding(.horizontal, 20.scaled)
    }
}

// MARK: - Subviews

private extension TermsAgreementView {

    var title: some View {
        Text("서비스 이용을 위해\n약관에 동의해주세요")
            .plobbyFont(.heading)
            .foregroundStyle(Color(.textPrimary))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 72.scaled)
            .padding(.bottom, 32.scaled)
    }

    var allAgreementRow: some View {
        Button {
            store.send(.allAgreementTapped)
        } label: {
            HStack(spacing: 12.scaled) {
                checkmark(isChecked: store.isAllAgreed)

                Text("전체 동의")
                    .plobbyFont(.cardTitle)
                    .foregroundStyle(Color(.textPrimary))

                Spacer()
            }
            .frame(height: 56.scaled)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 12.scaled)
    }

    func agreementRow(
        _ title: String,
        isChecked: Bool,
        action: SignUpFeature.Action,
        detailLink: ServiceLink? = nil
    ) -> some View {
        HStack(spacing: 12.scaled) {
            Button {
                store.send(action)
            } label: {
                HStack(spacing: 12.scaled) {
                    checkmark(isChecked: isChecked)

                    Text("[필수] \(title)")
                        .plobbyFont(.body)
                        .foregroundStyle(Color(.textPrimary))

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let url = detailLink?.url {
                Button {
                    openURL(url)
                } label: {
                    Text("보기")
                        .plobbyFont(.label)
                        .foregroundStyle(Color(.textSecondary))
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 48.scaled)
    }

    func checkmark(isChecked: Bool) -> some View {
        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
            .resizable()
            .frame(width: 24.scaled, height: 24.scaled)
            .foregroundStyle(isChecked ? Color(.green500) : Color(.gray300))
            .contentTransition(.identity)
            .transaction { $0.animation = nil }
    }
}

// MARK: - Preview

#Preview {
    TermsAgreementView(
        store: Store(initialState: SignUpFeature.State(user: AuthUser(id: UUID(), email: nil))) {
            SignUpFeature()
        }
    )
}
