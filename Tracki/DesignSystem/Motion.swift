//
//  Motion.swift
//  Tracki
//

import SwiftUI

/// Three curves, nothing else (B9).
enum Motion {
    /// State changes, toggles, selection. Fast, minimal overshoot.
    static let snappy = Animation.snappy(duration: 0.28, extraBounce: 0.08)
    /// Values, balances, content transitions. Smooth, no overshoot.
    static let smooth = Animation.smooth(duration: 0.45)
    /// Layers appearing/disappearing, sheets, the FAB. Springy.
    static let bouncy = Animation.bouncy(duration: 0.5, extraBounce: 0.15)
}
