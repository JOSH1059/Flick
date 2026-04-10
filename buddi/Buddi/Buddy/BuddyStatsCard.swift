import SwiftUI

/// Compact stats card shown in the buddy panel.
struct BuddyStatsCard: View {
    @ObservedObject private var stats = BuddyStats.shared
    @ObservedObject private var manager = BuddyManager.shared

    private var identity: BuddyIdentity { manager.effectiveIdentity }
    private var rarityColor: Color { Color(nsColor: identity.rarity.nsColor) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Rarity & Species
            HStack(spacing: 4) {
                Text(identity.rarity.stars)
                    .font(.caption2)
                    .foregroundColor(rarityColor)
                Text(identity.rarity.rawValue.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(rarityColor.opacity(0.8))
            }

            // Level & XP
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Lv. \(stats.level)")
                        .font(.caption2.weight(.bold).monospaced())
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stats.data.totalXP) XP")
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(rarityColor)
                            .frame(width: max(0, geo.size.width * stats.xpProgress))
                    }
                }
                .frame(height: 3)
            }

            // Affection
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(stats.affectionTitle)
                        .font(.caption2)
                        .foregroundColor(.pink.opacity(0.9))
                    Spacer()
                    Text("♥ \(stats.data.affection)")
                        .font(.caption2.monospaced())
                        .foregroundColor(.pink.opacity(0.6))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.pink.opacity(0.7))
                            .frame(width: max(0, geo.size.width * stats.affectionProgress))
                    }
                }
                .frame(height: 3)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Lifetime Stats
            VStack(alignment: .leading, spacing: 1) {
                statRow(icon: "hand.tap", label: "Pets", value: stats.data.petsReceived)
                statRow(icon: "checkmark.shield", label: "Approved", value: stats.data.toolsApproved)
                statRow(icon: "terminal", label: "Sessions", value: stats.data.sessionsParticipated)
                statRow(icon: "bubble.left", label: "Messages", value: stats.data.messagesWitnessed)
                if stats.data.buddyChats > 0 {
                    statRow(icon: "heart.bubble", label: "Chats", value: stats.data.buddyChats)
                }
            }

            // First met
            Text("Friends since \(stats.data.firstMet, format: .dateTime.month(.abbreviated).day().year())")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.vertical, 4)
    }

    private func statRow(icon: String, label: String, value: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundColor(.secondary)
                .frame(width: 10)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .font(.system(size: 8).monospaced())
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
