import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {
    // Pure black background requested by the user
    static let appBackground = Color.black

    // Dark sleek surfaces for cards and containers
    static let appCardBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let appSecondaryFill = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let appTertiaryFill = Color(red: 0.18, green: 0.18, blue: 0.18)
    static let appSystemFill = Color(red: 0.22, green: 0.22, blue: 0.22)
    static let appBorder = Color.white.opacity(0.14)

    // MARK: - Hex Conversion

    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 147, 161, 177)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let rgb: Int = (Int(r * 255) << 16) | (Int(g * 255) << 8) | Int(b * 255)
            return String(format: "#%06X", rgb)
        }
        return "#93A1B1"
        #else
        return "#93A1B1"
        #endif
    }
}

public extension View {
    @ViewBuilder
    func disableAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}

// MARK: - iOS Notes Style Toolbar Buttons

public struct CircularToolbarButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct CircularDismissButton: View {
    @Environment(\.dismiss) private var dismiss
    private let action: (() -> Void)?

    public init(action: (() -> Void)? = nil) {
        self.action = action
    }

    public var body: some View {
        Button {
            if let action = action {
                action()
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
        }
        .tint(.primary)
        .accessibilityLabel("Cerrar")
    }
}

public struct CircularSaveButton: View {
    private let isSaving: Bool
    private let isEnabled: Bool
    private let action: () -> Void

    public init(isSaving: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.isSaving = isSaving
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            if isSaving {
                ProgressView()
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .disabled(!isEnabled || isSaving)
        .tint(isEnabled ? .green : .secondary)
        .accessibilityLabel("Guardar")
    }
}
