//
//  PopupWindow.swift
//  Popup
//
//  Popup toàn cục hiển thị qua MỘT UIWindow riêng (windowLevel cao),
//  nên dim phủ TOÀN màn hình — kể cả tab bar, navigation bar — dù được
//  gọi từ bất kỳ view nào, không cần gắn modifier ở gốc.
//
//      Popup.show {
//          ToastView { Popup.dismiss() }
//      }
//
//  Tham số tùy chọn: dimOpacity, horizontalPadding, dismissOnTapOutside.
//

import SwiftUI
import UIKit
import Combine

// MARK: - Public API

@MainActor
enum Popup {
    /// Hiện popup toàn cục ở giữa màn hình (fade + phình nhẹ).
    /// - Parameter onDismiss: gọi khi popup bị đóng (kể cả do chạm ra ngoài).
    static func show<Content: View>(
        dimOpacity: Double = 0.35,
        horizontalPadding: CGFloat = 16,
        dismissOnTapOutside: Bool = true,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        presenter.show(
            dimOpacity: dimOpacity,
            horizontalPadding: horizontalPadding,
            dismissOnTapOutside: dismissOnTapOutside,
            onDismiss: onDismiss,
            content: content
        )
    }

    /// Đóng popup đang hiện (fade nhẹ rồi gỡ window).
    static func dismiss() {
        presenter.dismiss()
    }

    private static let presenter = PopupPresenter()
}

// MARK: - Presenter (quản lý vòng đời UIWindow)

@MainActor
private final class PopupPresenter {
    private let model = PopupModel()
    private var window: UIWindow?
    private var token = 0
    private var isDismissing = false
    private var onDismiss: (() -> Void)?

    private let animation: Animation = .easeInOut(duration: 0.22)
    private let duration: TimeInterval = 0.22

    func show<Content: View>(
        dimOpacity: Double,
        horizontalPadding: CGFloat,
        dismissOnTapOutside: Bool,
        onDismiss: (() -> Void)?,
        @ViewBuilder content: () -> Content
    ) {
        // Đang hiện thì gỡ ngay để thay nội dung mới.
        if window != nil { teardown() }
        token &+= 1
        isDismissing = false
        self.onDismiss = onDismiss

        guard let scene = Self.activeScene else { return }

        model.visible = false
        model.dimOpacity = dimOpacity
        model.horizontalPadding = horizontalPadding
        model.dismissOnTapOutside = dismissOnTapOutside
        model.content = AnyView(content())

        let root = PopupContainer(model: model) { [weak self] in
            self?.dismiss()
        }
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        host.view.accessibilityViewIsModal = true

        let win = UIWindow(windowScene: scene)
        win.frame = scene.windows.first?.bounds ?? UIScreen.main.bounds
        win.windowLevel = .alert + 1          // trên cả tab bar/nav bar
        win.backgroundColor = .clear
        win.rootViewController = host
        win.isHidden = false                  // không makeKey: tránh cướp first-responder của app
        window = win

        // Render trạng thái ẩn 1 frame rồi mới animate vào -> không bị snap.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(self.animation) { self.model.visible = true }
        }
    }

    func dismiss() {
        guard window != nil, !isDismissing else { return }
        isDismissing = true
        onDismiss?()                      // đồng bộ lại binding (nếu gọi qua modifier)
        let current = token
        withAnimation(animation) { model.visible = false }
        // Gỡ window sau khi fade xong; token chặn việc gỡ nhầm window mới.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, self.token == current else { return }
            self.teardown()
        }
    }

    private func teardown() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        model.content = nil
        onDismiss = nil
        isDismissing = false
    }

    private static var activeScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}

// MARK: - Model + View

@MainActor
private final class PopupModel: ObservableObject {
    @Published var visible = false
    @Published var dimOpacity: Double = 0.35
    @Published var horizontalPadding: CGFloat = 16
    @Published var dismissOnTapOutside = true
    @Published var content: AnyView?
}

private struct PopupContainer: View {
    @ObservedObject var model: PopupModel
    let onTapOutside: () -> Void

    var body: some View {
        ZStack {
            // Nền mờ phủ toàn window
            Color.black.opacity(model.visible ? model.dimOpacity : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    if model.dismissOnTapOutside { onTapOutside() }
                }

            // Card: chỉ animate opacity/scale, fade nguyên khối nhờ compositingGroup
            if let content = model.content {
                content
                    .padding(.horizontal, model.horizontalPadding)
                    .compositingGroup()
                    .opacity(model.visible ? 1 : 0)
                    .scaleEffect(model.visible ? 1 : 0.96)
            }
        }
    }
}
