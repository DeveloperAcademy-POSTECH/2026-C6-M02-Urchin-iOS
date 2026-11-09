//
//  PlobbyBottomSheet.swift
//  Plobby
//
//  Created by 더스틴 on 11/9/26.
//

import SwiftUI

/// 화면 좌우와 아래에 딱 붙는 바텀시트예요.
/// iOS 26 시스템 시트는 화면을 다 덮지 않는 높이에서 좌우·아래가 떠 있어서, 시트를 직접 그려요.
/// - 시트 높이는 내용이 정해요. 내용에 `.frame(height:)`로 홈 인디케이터 위 높이를 정해 주세요.
/// - 배경을 누르거나 아래로 끌면 닫혀요.
extension View {

    func plobbyBottomSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        cornerRadius: CGFloat = 24.scaled,
        showsGrabber: Bool = false,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(
            PlobbyBottomSheetModifier(
                item: item,
                cornerRadius: cornerRadius,
                showsGrabber: showsGrabber,
                sheetContent: content
            )
        )
    }

    func plobbyBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        cornerRadius: CGFloat = 24.scaled,
        showsGrabber: Bool = false,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        plobbyBottomSheet(
            item: Binding(
                get: { isPresented.wrappedValue ? PresentedSheet() : nil },
                set: { if $0 == nil { isPresented.wrappedValue = false } }
            ),
            cornerRadius: cornerRadius,
            showsGrabber: showsGrabber
        ) { _ in
            content()
        }
    }
}

/// 시트 모양(흰 배경, 위쪽 둥근 모서리, 손잡이)만 입혀요. 지도처럼 뒤 화면을 계속 만질 수 있어야 할 때 직접 얹어서 써요.
struct PlobbyBottomSheetPanel<Content: View>: View {

    var cornerRadius: CGFloat = 24.scaled
    var showsGrabber = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            // 내용에 사각 배경이 있어도 위쪽 모서리가 둥글게 보이게 잘라요.
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius))
            .background {
                UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                    .fill(Color(.gray0))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .top) {
                if showsGrabber {
                    Capsule()
                        .fill(Color(.gray300))
                        .frame(width: 36.scaled, height: 5.scaled)
                        .padding(.top, 5.scaled)
                }
            }
    }
}

// MARK: - Modifier

/// 띄운 화면 위에 시트를 직접 얹어요. 시스템 전체 화면 표시를 쓰면 표시 애니메이션이 내용 배치까지 움직여서 쓰지 않아요.
/// 시트가 떠 있는 동안 탭 바를 숨겨서 시트가 화면 아래 끝까지 덮어요.
/// 밖에서 닫아도(상태가 nil) 시트가 내려가는 애니메이션이 끝난 뒤에 거둬요.
private struct PlobbyBottomSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {

    @Binding var item: Item?
    let cornerRadius: CGFloat
    let showsGrabber: Bool
    let sheetContent: (Item) -> SheetContent

    @State private var presentedItem: Item?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let presented = presentedItem {
                    PlobbyBottomSheetContainer(
                        isPresented: item?.id == presented.id,
                        cornerRadius: cornerRadius,
                        showsGrabber: showsGrabber,
                        onDismissRequest: { item = nil },
                        onDismissed: { present(nil) }
                    ) {
                        sheetContent(presented)
                    }
                    .id(presented.id)
                }
            }
            .toolbar(presentedItem == nil ? .automatic : .hidden, for: .tabBar)
            .onAppear {
                if item != nil {
                    present(item)
                }
            }
            .onChange(of: item?.id) { _, id in
                // 닫을 때는 시트가 내려간 뒤에 거둬요.
                guard id != nil, presentedItem?.id != id else { return }
                present(item)
            }
    }

    /// 얹고 거두는 건 바로 하고, 시트 안에서 직접 올리고 내려요.
    private func present(_ item: Item?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            presentedItem = item
        }
    }
}

// MARK: - Container

private struct PlobbyBottomSheetContainer<Content: View>: View {

    let isPresented: Bool
    let cornerRadius: CGFloat
    let showsGrabber: Bool
    let onDismissRequest: () -> Void
    let onDismissed: () -> Void
    @ViewBuilder let content: Content

    @State private var isShown = false
    @State private var dragOffset: CGFloat = 0

    private var dimOpacity: CGFloat { 0.2 }
    /// 이만큼 끌어내리면 닫혀요.
    private var dismissDistance: CGFloat { 100 }

    /// 시트를 넣고 빼지 않고 위치만 옮겨요. 넣고 빼면 안쪽 내용의 배치까지 같이 움직여요.
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black
                    .opacity(isShown ? dimOpacity : 0)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismissRequest)

                let hiddenOffset = proxy.size.height + proxy.safeAreaInsets.bottom
                let offset = isShown ? dragOffset : hiddenOffset

                PlobbyBottomSheetPanel(cornerRadius: cornerRadius, showsGrabber: showsGrabber) {
                    // 시트를 올리고 내리는 애니메이션이 안쪽 배치에 번지지 않게 해요. 내용 안에서 직접 단 애니메이션은 그대로예요.
                    content
                        .transaction { $0.animation = nil }
                }
                // 배치는 그대로 두고 그려지는 위치만 옮겨요. 배치를 옮기면 지연 그리드가 올라오는 도중에 칸을 새로 만들며 흐트러져요.
                .visualEffect { content, _ in
                    content.offset(y: offset)
                }
                .gesture(dragGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.3)) {
                isShown = true
            }
        }
        .onChange(of: isPresented) { _, isPresented in
            guard !isPresented else { return }
            withAnimation(.smooth(duration: 0.25)) {
                isShown = false
            } completion: {
                onDismissed()
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffset = max(value.translation.height, 0)
            }
            .onEnded { value in
                if value.translation.height > dismissDistance || value.predictedEndTranslation.height > dismissDistance * 2 {
                    onDismissRequest()
                } else {
                    withAnimation(.smooth(duration: 0.2)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

/// `isPresented`로 띄우는 시트를 `item` 방식으로 다루기 위한 값이에요.
private struct PresentedSheet: Identifiable {
    let id = 0
}
