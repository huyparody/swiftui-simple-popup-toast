# SwiftUI Simple Popup / Toast

A lightweight, native-feeling center popup for SwiftUI. It fades in from the middle of the screen, fades out cleanly, and — because it renders in its own `UIWindow` — its dimmed background covers **the entire screen**, including the tab bar and navigation bar, no matter where you call it from.

> 🇻🇳 [Tiếng Việt](#tiếng-việt) · 🇬🇧 [English](#english)

Pure SwiftUI + a thin UIKit window bridge. No third-party dependencies.

---

## Tiếng Việt

### Tính năng

- **Hiện ra từ giữa màn hình**, fade nhẹ + phình nhẹ (scale 0.96 → 1.0).
- **Đóng fade mượt**, không giật một frame (card chỉ animate `opacity`/`scale`, không insert/remove view; `compositingGroup()` để fade nguyên khối).
- **Dim phủ TOÀN màn hình** — kể cả tab bar / navigation bar — vì chạy trong một `UIWindow` riêng ở `windowLevel` cao.
- Gọi được từ **bất kỳ đâu**: qua modifier `.popup(isPresented:)` (như `.sheet`) hoặc imperative `Popup.show { }`.
- Thuần SwiftUI, không thư viện ngoài.

### Yêu cầu

- iOS 17.0+
- Swift 5.9+ / Xcode 15+

### Cài đặt

Chép 2 file vào dự án:

- `Popup/PopupWindow.swift` — engine (UIWindow + presenter + animation).
- `Popup/View+Popup.swift` — modifier `.popup(isPresented:)`.

### Cách dùng

**1. Modifier (giống `.sheet`)**

```swift
@State private var showPopup = false

SomeView()
    .popup(isPresented: $showPopup) {
        MyCard { showPopup = false }   // đóng = set cờ về false
    }
```

**2. Imperative (gọi từ logic bất kỳ)**

```swift
Popup.show {
    MyCard { Popup.dismiss() }
}

Popup.dismiss()
```

### Tham số

| Tham số | Mặc định | Ý nghĩa |
|---|---|---|
| `dimOpacity` | `0.35` | Độ tối của nền mờ phía sau |
| `horizontalPadding` | `16` | Lề trái/phải của popup so với mép màn hình |
| `dismissOnTapOutside` | `true` | Chạm ra ngoài để đóng |

### Cách hoạt động

- Một `UIWindow` riêng ở `windowLevel = .alert + 1` → đứng trên cả tab bar/nav bar, nên dim phủ toàn màn hình dù gọi từ view sâu cỡ nào.
- **Không** `makeKey` → không cướp first-responder/bàn phím của app.
- Card luôn ở trong cây view, chỉ animate `opacity`/`scaleEffect`; cả dim + card chạy cùng một nhịp `easeInOut(0.22)` → không có cú giật một frame.
- Đóng xong gỡ window sạch (`isHidden`, `rootViewController = nil`, `window = nil`), có token chặn gỡ nhầm khi show/dismiss chồng nhau.
- `accessibilityViewIsModal = true` để VoiceOver coi đây là lớp modal.

### Lưu ý

- Popup chạy trong window riêng nên **không kế thừa** `@Environment` (theme, accent tùy biến…) từ view gọi nó. Nếu cần, set ngay trong nội dung truyền vào.
- Mỗi lần chỉ hiện **một** popup; gọi `show` khi đang hiện sẽ thay nội dung mới.

---

## English

### Features

- **Appears from the center** of the screen with a gentle fade + slight scale (0.96 → 1.0).
- **Smooth fade-out** with no one-frame jump (the card only animates `opacity`/`scale` instead of being inserted/removed; `compositingGroup()` makes it fade as a single layer).
- **Dimmed background covers the WHOLE screen** — including the tab bar / navigation bar — because it lives in its own high-level `UIWindow`.
- Call it from **anywhere**: via the `.popup(isPresented:)` modifier (like `.sheet`) or imperatively with `Popup.show { }`.
- Pure SwiftUI, no third-party dependencies.

### Requirements

- iOS 17.0+
- Swift 5.9+ / Xcode 15+

### Installation

Copy two files into your project:

- `Popup/PopupWindow.swift` — the engine (UIWindow + presenter + animation).
- `Popup/View+Popup.swift` — the `.popup(isPresented:)` modifier.

### Usage

**1. Modifier (like `.sheet`)**

```swift
@State private var showPopup = false

SomeView()
    .popup(isPresented: $showPopup) {
        MyCard { showPopup = false }   // dismiss = set the flag back to false
    }
```

**2. Imperative (from any logic)**

```swift
Popup.show {
    MyCard { Popup.dismiss() }
}

Popup.dismiss()
```

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `dimOpacity` | `0.35` | Opacity of the dimmed background |
| `horizontalPadding` | `16` | Popup's left/right padding from the screen edges |
| `dismissOnTapOutside` | `true` | Tap outside to dismiss |

### How it works

- A dedicated `UIWindow` at `windowLevel = .alert + 1` sits above the tab bar/nav bar, so the dim covers the full screen regardless of how deep the call site is.
- It does **not** `makeKey`, so it won't steal the app's first responder/keyboard.
- The card stays mounted and only animates `opacity`/`scaleEffect`; the dim and card share a single `easeInOut(0.22)` beat → no one-frame stutter.
- On dismiss the window is torn down cleanly (`isHidden`, `rootViewController = nil`, `window = nil`), with a token guarding against tearing down a newer window when show/dismiss overlap.
- `accessibilityViewIsModal = true` so VoiceOver treats it as a modal layer.

### Notes

- Because it runs in a separate window, the popup does **not** inherit `@Environment` (custom theme, accent, etc.) from the calling view. Set those inside the content you pass in if needed.
- Only **one** popup shows at a time; calling `show` while one is visible replaces its content.
