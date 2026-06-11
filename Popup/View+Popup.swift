//
//  View+Popup.swift
//  Popup
//
//  Popup ở giữa màn hình: hiện ra fade + phình nhẹ, đóng fade nhẹ.
//  Dùng như .sheet:
//
//      .popup(isPresented: $show) {
//          MyCard { show = false }
//      }
//

import SwiftUI

extension View {
    /// Hiển thị một popup ở giữa màn hình với hiệu ứng fade nhẹ.
    /// - Parameters:
    ///   - isPresented: bật/tắt popup. Tự animate khi đổi giá trị.
    ///   - dimOpacity: độ tối của nền mờ phía sau (mặc định 0.35).
    ///   - dismissOnTapOutside: chạm ra ngoài để đóng (mặc định true).
    ///   - content: nội dung popup.
    func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        dimOpacity: Double = 0.35,
        dismissOnTapOutside: Bool = true,
        @ViewBuilder content: () -> PopupContent
    ) -> some View {
        modifier(
            PopupModifier(
                isPresented: isPresented,
                dimOpacity: dimOpacity,
                dismissOnTapOutside: dismissOnTapOutside,
                popupContent: content()
            )
        )
    }
}

private struct PopupModifier<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dimOpacity: Double
    let dismissOnTapOutside: Bool
    let popupContent: PopupContent

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    // Nền mờ
                    Color.black.opacity(isPresented ? dimOpacity : 0)
                        .ignoresSafeArea()
                        .allowsHitTesting(isPresented)
                        .onTapGesture {
                            if dismissOnTapOutside { isPresented = false }
                        }

                    // Card: luôn ở trong cây view, chỉ animate opacity/scale
                    // -> không bị "giật 1 frame" như khi insert/remove + .transition.
                    popupContent
                        .padding(.horizontal, 24)
                        .compositingGroup() // fade như một khối: nền + chữ + shadow cùng nhau
                        .opacity(isPresented ? 1 : 0)
                        .scaleEffect(isPresented ? 1 : 0.96)
                        .allowsHitTesting(isPresented)
                        .accessibilityHidden(!isPresented)
                }
                // Hiện & đóng cùng một nhịp cho cả dim + card.
                .animation(.easeInOut(duration: 0.22), value: isPresented)
            }
    }
}
