//
//  View+Popup.swift
//  Popup
//
//  Modifier .popup(isPresented:) dùng như .sheet, nhưng bên trong chạy
//  bằng UIWindow riêng (xem PopupWindow.swift) nên dim phủ TOÀN màn hình
//  — kể cả tab bar / navigation bar — dù gắn ở bất kỳ view nào.
//
//      .popup(isPresented: $show) {
//          ToastView { show = false }
//      }
//

import SwiftUI

extension View {
    /// Hiển thị popup toàn cục ở giữa màn hình (fade nhẹ) theo cờ `isPresented`.
    /// - Parameters:
    ///   - isPresented: bật/tắt popup. Đặt `false` (vd từ nút trong card) để đóng.
    ///   - dimOpacity: độ tối của nền mờ (mặc định 0.35).
    ///   - horizontalPadding: lề trái/phải của popup so với mép màn hình (mặc định 16).
    ///   - dismissOnTapOutside: chạm ra ngoài để đóng (mặc định true).
    ///   - content: nội dung popup.
    func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        dimOpacity: Double = 0.35,
        horizontalPadding: CGFloat = 16,
        dismissOnTapOutside: Bool = true,
        @ViewBuilder content: @escaping () -> PopupContent
    ) -> some View {
        modifier(
            PopupPresentationModifier(
                isPresented: isPresented,
                dimOpacity: dimOpacity,
                horizontalPadding: horizontalPadding,
                dismissOnTapOutside: dismissOnTapOutside,
                popupContent: content
            )
        )
    }
}

private struct PopupPresentationModifier<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dimOpacity: Double
    let horizontalPadding: CGFloat
    let dismissOnTapOutside: Bool
    @ViewBuilder let popupContent: () -> PopupContent

    func body(content: Content) -> some View {
        content
            // Hiện ngay cả khi vào màn đã ở trạng thái isPresented == true.
            .onAppear { if isPresented { present() } }
            .onChange(of: isPresented) { _, shown in
                if shown { present() } else { Popup.dismiss() }
            }
    }

    private func present() {
        Popup.show(
            dimOpacity: dimOpacity,
            horizontalPadding: horizontalPadding,
            dismissOnTapOutside: dismissOnTapOutside,
            onDismiss: { isPresented = false }   // tap ngoài -> đồng bộ lại cờ
        ) {
            popupContent()
        }
    }
}
