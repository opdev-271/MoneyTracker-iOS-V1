//
//  GlassSegmentedPicker.swift
//  Tracki
//

import SwiftUI

/// Segmented control used in 5 places (transaction type, analytics period,
/// language, theme, currency). The sliding pill can be dragged with a finger,
/// not just tapped — a detail worth carrying over from Android (B7.4).
struct GlassSegmentedPicker<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    @State private var dragOffset: CGFloat = 0
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animate: Bool { appSettings.shouldAnimate(reduceMotion: reduceMotion) }

    var body: some View {
        GeometryReader { geo in
            let segmentWidth = geo.size.width / CGFloat(max(options.count, 1))
            let selectedIndex = options.firstIndex { $0.value == selection } ?? 0

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Tokens.accent)
                    .frame(width: max(segmentWidth - 4, 0), height: max(geo.size.height - 4, 0))
                    .offset(x: CGFloat(selectedIndex) * segmentWidth + 2 + dragOffset)
                    .shadow(color: Tokens.accent.opacity(0.35), radius: 8, y: 3)

                HStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { i in
                        Text(options[i].label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(i == selectedIndex ? Tokens.onAccent : Tokens.textSecondary)
                            .frame(width: segmentWidth, height: geo.size.height)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                select(options[i].value, animate: animate)
                            }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        let maxOffset = segmentWidth * CGFloat(options.count - 1 - selectedIndex)
                        let minOffset = -segmentWidth * CGFloat(selectedIndex)
                        dragOffset = min(max(value.translation.width, minOffset), maxOffset)
                    }
                    .onEnded { _ in
                        let landed = Int(round((CGFloat(selectedIndex) * segmentWidth + dragOffset) / segmentWidth))
                        let clamped = min(max(landed, 0), options.count - 1)
                        dragOffset = 0
                        select(options[clamped].value, animate: animate)
                    }
            )
        }
        .frame(height: 44)
        .liquidGlass(Capsule(style: .continuous))
    }

    private func select(_ value: T, animate: Bool) {
        Haptics.selection()
        if animate {
            withAnimation(Motion.snappy) { selection = value }
        } else {
            selection = value
        }
    }
}
