import Combine
import Defaults
import Foundation

/// Singleton that holds the buddy identity and sprite animator.
/// Initialized once at app launch via BuddyDetector.detect().
/// Override keys let users customize species/eye/hat while preserving the original roll.
@MainActor
final class BuddyManager: ObservableObject {
    static let shared = BuddyManager()

    /// The original randomly-generated identity (never mutated).
    let identity: BuddyIdentity

    /// The identity with user overrides applied. Observe this for rendering.
    @Published private(set) var effectiveIdentity: BuddyIdentity

    let animator: SpriteAnimator

    private var cancellables = Set<AnyCancellable>()

    private init() {
        let detected = BuddyDetector.detect()
        self.identity = detected
        self.effectiveIdentity = Self.applyOverrides(to: detected)
        self.animator = SpriteAnimator(identity: Self.applyOverrides(to: detected))
        observeOverrides()
    }

    private func observeOverrides() {
        let speciesPublisher = Defaults.publisher(.buddySpeciesOverride, options: [])
        let eyePublisher = Defaults.publisher(.buddyEyeOverride, options: [])
        let hatPublisher = Defaults.publisher(.buddyHatOverride, options: [])
        let rarityPublisher = Defaults.publisher(.buddyRarityOverride, options: [])

        speciesPublisher.merge(with: eyePublisher, hatPublisher, rarityPublisher)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshEffectiveIdentity()
            }
            .store(in: &cancellables)
    }

    private func refreshEffectiveIdentity() {
        let updated = Self.applyOverrides(to: identity)
        guard updated != effectiveIdentity else { return }
        effectiveIdentity = updated
        animator.identity = updated
    }

    private static func applyOverrides(to base: BuddyIdentity) -> BuddyIdentity {
        var result = base
        if let raw = Defaults[.buddySpeciesOverride], let species = BuddySpecies(rawValue: raw) {
            result.species = species
        }
        if let raw = Defaults[.buddyEyeOverride], let eye = BuddyEye(rawValue: raw) {
            result.eye = eye
        }
        if let raw = Defaults[.buddyHatOverride], let hat = BuddyHat(rawValue: raw) {
            result.hat = hat
        }
        if let raw = Defaults[.buddyRarityOverride], let rarity = BuddyRarity(rawValue: raw) {
            result.rarity = rarity
        }
        return result
    }
}
