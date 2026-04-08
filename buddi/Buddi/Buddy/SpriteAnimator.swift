import Combine
import Foundation

/// Pure logic class that computes animation frame strings.
/// Owns the timer. Testable without any UI dependency.
///
/// Usage:
///   let animator = SpriteAnimator(identity: identity)
///   animator.task = .working  // timer resets, frames change
///   animator.$frameString    // observe the current rendered string
@MainActor
final class SpriteAnimator: ObservableObject {
    @Published private(set) var frameString: String = ""
    @Published private(set) var oneLine: String = ""

    var task: BuddyTask = .idle {
        didSet {
            guard task != oldValue else { return }
            tick = 0
            successCountdown = task == .success ? 5 : 0
            updateFrame()
            restartTimer()
        }
    }

    var identity: BuddyIdentity {
        didSet {
            guard identity != oldValue else { return }
            updateFrame()
        }
    }
    private var tick: Int = 0
    private var timer: Timer?
    private var successCountdown: Int = 0

    init(identity: BuddyIdentity) {
        self.identity = identity
        updateFrame()
        restartTimer()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Timer

    private func restartTimer() {
        timer?.invalidate()
        let interval = intervalForTask(task)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.onTick()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func onTick() {
        tick += 1

        if task == .success {
            successCountdown -= 1
            if successCountdown <= 0 {
                task = .idle
                return
            }
        }

        updateFrame()
    }

    private func updateFrame() {
        frameString = SpriteFrameLogic.frame(
            for: task,
            tick: tick,
            species: identity.species,
            eye: identity.eye
        )
        oneLine = SpriteFrameLogic.oneLineFace(
            for: task,
            species: identity.species,
            eye: identity.eye
        )
    }

    private func intervalForTask(_ task: BuddyTask) -> TimeInterval {
        switch task {
        case .idle: 0.5       // 500ms tick
        case .working: 0.4    // 400ms cursor toggle
        case .reading: 0.8    // 800ms eye shift
        case .waiting: 0.5    // 500ms dot animation
        case .compacting: 0.4 // 400ms tilde
        case .sleeping: 1.2   // 1.2s zzz scroll
        case .error: 0.5      // 500ms
        case .success: 0.5    // 500ms countdown
        }
    }
}

// MARK: - Pure Frame Logic (nonisolated, testable)

enum SpriteFrameLogic {
    static let idleSequence: [Int] = [0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 2, 0, 0, 0]

    static func frame(
        for task: BuddyTask,
        tick: Int,
        species: BuddySpecies,
        eye: BuddyEye
    ) -> String {
        let baseFace = SpriteData.face(species: species, eye: eye)

        switch task {
        case .idle:
            let seq = idleSequence
            let index = tick % seq.count
            let value = seq[index]
            if value == -1 {
                return blinkFace(baseFace, eye: eye)
            }
            return baseFace

        case .working:
            let cursor = tick % 2 == 0 ? "|" : ""
            return baseFace + cursor

        case .reading:
            let phase = tick % 3
            if phase == 1 {
                return shiftEyeRight(baseFace, eye: eye)
            }
            return baseFace

        case .waiting:
            let dots = String(repeating: ".", count: (tick % 3) + 1)
            return baseFace + dots

        case .compacting:
            let suffix = tick % 2 == 0 ? "~" : "~~"
            return baseFace + suffix

        case .sleeping:
            let zCount = (tick % 3) + 1
            let zzz = String(repeating: "z", count: zCount)
            return sleepFace(baseFace, eye: eye) + " " + zzz

        case .error:
            return errorFace(baseFace, eye: eye)

        case .success:
            return baseFace + " \u{2713}"
        }
    }

    static func oneLineFace(for task: BuddyTask, species: BuddySpecies, eye: BuddyEye) -> String {
        let base = SpriteData.face(species: species, eye: eye)
        let suffix = task.faceSuffix
        if task == .sleeping {
            return sleepFace(base, eye: eye) + suffix
        }
        if task == .error {
            return errorFace(base, eye: eye) + suffix
        }
        return base + suffix
    }

    static func blinkFace(_ face: String, eye: BuddyEye) -> String {
        face.replacingOccurrences(of: eye.rawValue, with: "-")
    }

    static func sleepFace(_ face: String, eye: BuddyEye) -> String {
        face.replacingOccurrences(of: eye.rawValue, with: "-")
    }

    static func errorFace(_ face: String, eye: BuddyEye) -> String {
        face.replacingOccurrences(of: eye.rawValue, with: "X")
    }

    static func shiftEyeRight(_ face: String, eye: BuddyEye) -> String {
        guard let range = face.range(of: eye.rawValue) else { return face }
        var result = face
        result.replaceSubrange(range, with: " ")
        return result
    }
}
