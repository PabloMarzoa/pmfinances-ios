import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - App Appearance Modes

public enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    public var localizedTitle: LocalizedStringKey {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }
}

public extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        }))
        #else
        return dark
        #endif
    }

    // Adaptive background: pure black in dark mode, clean iOS native gray (#F2F2F7) in light mode
    static let appBackground = Color.dynamic(
        light: Color(red: 242/255, green: 242/255, blue: 247/255),
        dark: Color.black
    )

    // Surfaces for cards and containers: pure white in light mode, dark sleek surfaces in dark mode
    static let appCardBackground = Color.dynamic(
        light: Color.white,
        dark: Color(red: 0.08, green: 0.08, blue: 0.08)
    )

    // Secondary fills (search bars, filter chips, secondary buttons):
    static let appSecondaryFill = Color.dynamic(
        light: Color(red: 236/255, green: 236/255, blue: 239/255),
        dark: Color(red: 0.13, green: 0.13, blue: 0.13)
    )

    // Tertiary fills (chip background, tags):
    static let appTertiaryFill = Color.dynamic(
        light: Color(red: 228/255, green: 228/255, blue: 233/255),
        dark: Color(red: 0.18, green: 0.18, blue: 0.18)
    )

    // System fills:
    static let appSystemFill = Color.dynamic(
        light: Color(red: 218/255, green: 218/255, blue: 224/255),
        dark: Color(red: 0.22, green: 0.22, blue: 0.22)
    )

    // Standard subtle border for controls, buttons, text fields, chips and content
    static let appBorder = Color.dynamic(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.14)
    )

    // Brand purple matching the PMFinances app logo (#8233CD)
    static let appLogoPurple = Color(hex: "#8233CD")

    // Card border: subtle border in light mode, subtle white in dark mode
    static let appCardBorder = Color.dynamic(
        light: Color.black.opacity(0.06),
        dark: Color.white.opacity(0.14)
    )

    // Subtle divider line for internal list/menu separators
    static let appDivider = Color.dynamic(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.12)
    )

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

    @MainActor
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
    func appCardShadow(radius: CGFloat = 8, y: CGFloat = 3, opacity: Double? = nil) -> some View {
        self.modifier(AppCardShadowModifier(radius: radius, y: y, customOpacity: opacity))
    }

    @ViewBuilder
    func disableAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}

private struct AppCardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let radius: CGFloat
    let y: CGFloat
    let customOpacity: Double?

    func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        let defaultOpacity: Double = isDark ? 0.22 : 0.08
        let finalOpacity = customOpacity ?? defaultOpacity

        if isDark {
            content.shadow(
                color: Color.appLogoPurple.opacity(finalOpacity),
                radius: radius,
                x: 0,
                y: y
            )
        } else {
            content
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: max(radius * 0.5, 2),
                    x: 0,
                    y: max(y * 0.6, 1)
                )
                .shadow(
                    color: Color.appLogoPurple.opacity(finalOpacity * 0.8),
                    radius: radius,
                    x: 0,
                    y: y
                )
        }
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
