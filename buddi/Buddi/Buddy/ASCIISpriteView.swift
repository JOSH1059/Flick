import SwiftUI

/// Renders the ASCII buddy face using Menlo 16px.
struct ASCIISpriteView: View {
    @ObservedObject var animator: SpriteAnimator
    let rarity: BuddyRarity
    let isError: Bool

    var body: some View {
        Text(animator.frameString)
            .font(.system(size: 16, design: .monospaced))
            .foregroundColor(textColor)
            .lineLimit(1)
            .fixedSize()
            .drawingGroup()
    }

    private var textColor: Color {
        if isError { return .red }
        return Color(nsColor: rarity.nsColor)
    }
}

/// Multi-line animated sprite view for the expanded panel.
/// Uses TimelineView for smooth frame cycling.
struct ASCIIFullSpriteView: View {
    @ObservedObject var animator: SpriteAnimator
    let identity: BuddyIdentity
    var fontSize: CGFloat = 12

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.8, paused: false)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate / 0.8)
            let lines = spriteLines(tick: tick)

            VStack(alignment: .center, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(textColor)
                }
            }
        }
    }

    private func spriteLines(tick: Int) -> [String] {
        let eye: BuddyEye
        switch animator.task {
        case .error: eye = .cross
        case .sleeping: eye = .dot
        default: eye = identity.eye
        }

        return SpriteData.renderFrame(
            species: identity.species,
            eye: eye,
            hat: identity.hat,
            frame: tick
        )
    }

    private var textColor: Color {
        if animator.task == .error { return .red }
        return Color(nsColor: identity.rarity.nsColor)
    }
}
