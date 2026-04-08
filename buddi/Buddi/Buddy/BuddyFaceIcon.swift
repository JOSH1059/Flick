import SwiftUI

/// Replaces ClaudeCrabIcon — renders the buddy's one-line face in monospace with blink animation.
struct BuddyFaceIcon: View {
    var fontSize: CGFloat = 10
    var animated: Bool = true

    private var identity: BuddyIdentity { BuddyManager.shared.effectiveIdentity }

    private static let blinkSequence = [0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.3, paused: !animated)) { timeline in
            let tick = animated ? Int(timeline.date.timeIntervalSinceReferenceDate / 0.3) : 0
            let idx = tick % Self.blinkSequence.count
            let isBlinking = Self.blinkSequence[idx] == 1

            let displayFace = isBlinking
                ? SpriteData.face(species: identity.species, eye: identity.eye)
                    .replacingOccurrences(of: identity.eye.rawValue, with: "-")
                : SpriteData.face(species: identity.species, eye: identity.eye)

            Text(displayFace)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(Color(nsColor: identity.rarity.nsColor))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
