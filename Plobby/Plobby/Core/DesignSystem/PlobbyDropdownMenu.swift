//
//  PlobbyDropdownMenu.swift
//  Plobby
//
//  Created by 더스틴 on 11/11/26.
//

import SwiftUI

/// 버튼 아래에 펼쳐지는 메뉴예요. 시스템 Menu 대신 디자인 시스템 모양으로 그려요.
/// - 항목을 누르면 메뉴를 닫고 동작을 실행해요.
/// - 메뉴 밖을 누르면 닫혀요.
struct PlobbyDropdownMenu: View {

    // MARK: - Properties

    let items: [Item]
    let onSelect: (Item) -> Void

    static var width: CGFloat { 184 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4.scaled) {
            ForEach(items) { item in
                Button {
                    onSelect(item)
                } label: {
                    row(item)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8.scaled)
        .frame(width: Self.width.scaled)
        .background(Color(.gray0), in: RoundedRectangle(cornerRadius: 16.scaled))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }

    private func row(_ item: Item) -> some View {
        HStack(spacing: 8.scaled) {
            Image(systemName: item.systemImage)
                .font(.system(size: 16.scaled, weight: .medium))
                .frame(width: 20.scaled, height: 20.scaled)

            Text(item.title)
                .plobbyFont(.label)

            Spacer(minLength: 0)
        }
        .foregroundStyle(item.isDestructive ? Color(.currentError) : Color(.textPrimary))
        .padding(.horizontal, 12.scaled)
        .frame(height: 44.scaled)
        .contentShape(RoundedRectangle(cornerRadius: 8.scaled))
    }
}

// MARK: - Item

extension PlobbyDropdownMenu {

    struct Item: Identifiable {

        let id = UUID()
        let title: String
        let systemImage: String
        var isDestructive = false
        let action: () -> Void
    }
}

/// 기록 더보기에서 쓰는 항목이에요. 내 기록은 수정·삭제, 다른 사람 기록은 신고·차단이에요.
extension PlobbyDropdownMenu.Item {

    static func edit(_ action: @escaping () -> Void) -> Self {
        Self(title: "수정하기", systemImage: "pencil", action: action)
    }

    static func delete(_ action: @escaping () -> Void) -> Self {
        Self(title: "삭제하기", systemImage: "trash", isDestructive: true, action: action)
    }

    static func report(_ action: @escaping () -> Void) -> Self {
        Self(title: "신고하기", systemImage: "light.beacon.max", action: action)
    }

    static func block(_ action: @escaping () -> Void) -> Self {
        Self(title: "차단하기", systemImage: "nosign", isDestructive: true, action: action)
    }
}

// MARK: - Modifier

extension View {

    func plobbyDropdownMenu(
        isPresented: Binding<Bool>,
        alignment: Alignment = .topTrailing,
        padding: EdgeInsets,
        items: [PlobbyDropdownMenu.Item]
    ) -> some View {
        overlay(alignment: alignment) {
            if isPresented.wrappedValue {
                ZStack(alignment: alignment) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isPresented.wrappedValue = false
                        }

                    PlobbyDropdownMenu(items: items) { item in
                        isPresented.wrappedValue = false
                        item.action()
                    }
                    .padding(padding)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                }
            }
        }
        .animation(.easeOut(duration: 0.15), value: isPresented.wrappedValue)
    }
}

// MARK: - Anchored

private struct PlobbyDropdownAnchorKey: PreferenceKey {

    static var defaultValue: Anchor<CGRect>? { nil }

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

extension View {

    func plobbyDropdownAnchor(isPresented: Bool) -> some View {
        anchorPreference(key: PlobbyDropdownAnchorKey.self, value: .bounds) { isPresented ? $0 : nil }
    }

    func plobbyAnchoredDropdownMenu(
        isPresented: Binding<Bool>,
        items: [PlobbyDropdownMenu.Item]
    ) -> some View {
        overlayPreferenceValue(PlobbyDropdownAnchorKey.self) { anchor in
            GeometryReader { proxy in
                if isPresented.wrappedValue, let anchor {
                    let buttonFrame = proxy[anchor]

                    ZStack(alignment: .topLeading) {
                        // 메뉴 밖을 누르면 닫혀요.
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isPresented.wrappedValue = false
                            }

                        PlobbyDropdownMenu(items: items) { item in
                            isPresented.wrappedValue = false
                            item.action()
                        }
                        .offset(
                            x: buttonFrame.maxX - PlobbyDropdownMenu.width.scaled,
                            y: buttonFrame.maxY + 4.scaled
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.15), value: isPresented.wrappedValue)
    }
}
