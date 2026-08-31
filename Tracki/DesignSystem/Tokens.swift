//
//  Tokens.swift
//  Tracki
//

import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        self.init(hex: UInt32(value))
    }

    /// A color that resolves to `light` or `dark` based on the active trait
    /// collection — driven by `preferredColorScheme`, not a hardcoded
    /// `if colorScheme == .dark` check, so it also behaves correctly inside
    /// previews, widgets, and anywhere else SwiftUI resolves colors natively.
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// Port of `ContrastColor`: picks dark or white foreground based on the
    /// relative luminance of this color used as a background.
    var contrastingForeground: Color {
        UIColor(self).relativeLuminance > 0.45 ? Tokens.textPrimary : Color.white
    }

    /// `Color.mix(with:by:)` is iOS 18+; this shim blends manually below that.
    func mixed(with other: Color, by fraction: Double) -> Color {
        if #available(iOS 18.0, *) {
            return mix(with: other, by: fraction)
        }
        let c1 = UIColor(self)
        let c2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(fraction)
        return Color(
            red: Double(r1 + (r2 - r1) * f),
            green: Double(g1 + (g2 - g1) * f),
            blue: Double(b1 + (b2 - b1) * f),
            opacity: Double(a1 + (a2 - a1) * f)
        )
    }
}

extension UIColor {
    /// WCAG relative luminance.
    var relativeLuminance: Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}

/// Color tokens ported from the Android palette (B2), plus the tokens the
/// Liquid Glass system needs that Android never had.
enum Tokens {
    // MARK: Surfaces
    static let pageBase = Color.adaptive(light: Color(hex: 0xF7F7F7), dark: Color(hex: 0x1F221D))
    static let surface = Color.adaptive(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1F221D))
    static let surfaceRaised = Color.adaptive(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x262A23))
    static let surfaceSunken = Color.adaptive(light: Color(hex: 0xEFEFEF), dark: Color(hex: 0x2B2E27))
    static let surfaceSunkenDeep = Color.adaptive(light: Color(hex: 0xE2E2E2), dark: Color(hex: 0x363A32))

    // MARK: Text
    static let textPrimary = Color.adaptive(light: Color(hex: 0x1A1A1A), dark: Color(hex: 0xF4F6EE))
    static let textSecondary = Color.adaptive(light: Color(hex: 0x777777), dark: Color(hex: 0xA4A99A))
    static let textTertiary = Color.adaptive(light: Color(hex: 0xABABAB), dark: Color(hex: 0x6F746A))

    // MARK: Accent
    /// Signature lime — same in both modes, since it's light enough that
    /// content drawn on it is always dark.
    static let accent = Color(hex: 0xD9F55F)
    /// The accent as *text/icon* color on ordinary surfaces (raw lime would
    /// vanish visually against a light page).
    static let accentOnSurface = Color.adaptive(light: Color(hex: 0x7A9C18), dark: Color(hex: 0xD9F55F))
    static let onAccent = Color.adaptive(light: Color(hex: 0x1A1A1A), dark: Color(hex: 0x181A12))
    static let lavender = Color(hex: 0xB9B3F4)
    static let coral = Color(hex: 0xF2907B)

    // MARK: Amount semantics
    static let income = Color.adaptive(light: Color(hex: 0x7A9C18), dark: Color(hex: 0xD9F55F))
    static let expense = Color.adaptive(light: Color(hex: 0xE2674A), dark: Color(hex: 0xF2907B))

    // MARK: Glass
    static let glassTint = Color.adaptive(light: Color.white.opacity(0.22), dark: Color(hex: 0x2F332B).opacity(0.30))
    static let glassRimTop = Color.adaptive(light: Color.white.opacity(0.75), dark: Color.white.opacity(0.40))
    static let glassRimBottom = Color.adaptive(light: Color.white.opacity(0.20), dark: Color.white.opacity(0.08))
    static let hairline = Color.adaptive(light: Color(hex: 0xE8E8E8), dark: Color(hex: 0x3C4038))

    // MARK: Shadows — dark and translucent, never light (A9.2)
    static let shadowAmbient = Color.black.opacity(0.10)
    static let shadowKey = Color.black.opacity(0.16)
}

/// User-pickable color palettes, ported unchanged from Android (B2).
enum Palette {
    /// Accounts, profiles, envelopes (7 colors).
    static let accountColors: [String] = [
        "181A12", "D9F55F", "B9B3F4", "F2907B", "8EC9F0", "F2C94C", "7ED9A7",
    ]

    /// Categories (20 colors, 4×5 grid). Deliberately mid-saturation: doubles
    /// as both the badge fill under the icon and the pie chart slice.
    static let categoryColors: [String] = [
        "F2907B", "E2674A", "D9534F", "E8739E",
        "B9B3F4", "9B8CE8", "7C6FD6", "8EC9F0",
        "5AA9E6", "4FC3C7", "7ED9A7", "5FBF7F",
        "A9C93F", "D9F55F", "F2C94C", "E9A23B",
        "C98B5E", "9AA091", "6F746A", "181A12",
    ]
}
