//
//  Spacing.swift
//  Tracki
//

import CoreGraphics

/// Radii — kept concentric on purpose (inner = outer − padding), see B6.
/// Always pair with `.rect(cornerRadius:style: .continuous)`, not the plain
/// circular corner style.
enum Radius {
    static let card: CGFloat = 28
    static let cardSmall: CGFloat = 22
    static let inner: CGFloat = 14
    static let sheet: CGFloat = 32
    static let pill: CGFloat = 999
}

enum Space {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let screen: CGFloat = 20
}
