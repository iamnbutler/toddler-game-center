/// Rules for the colors game: the screen asks for a color, the player taps the
/// matching blob out of three. Five right answers wins.
///
/// A value type with no timers. After a right answer the game celebrates and
/// ignores picks until the view calls ``nextRound()``, so the view owns the pause.
public struct ColorGame: Sendable {
    public struct NamedColor: Equatable, Hashable, Sendable {
        public let name: String
        /// 0xRRGGBB, so the rules don't depend on SwiftUI.
        public let hex: UInt32
    }

    public enum PickResult: Equatable, Sendable {
        case ignored, correct, tryAgain, won
    }

    public static let palette: [NamedColor] = [
        NamedColor(name: "red", hex: 0xE53935),
        NamedColor(name: "blue", hex: 0x1E88E5),
        NamedColor(name: "yellow", hex: 0xFDD835),
        NamedColor(name: "green", hex: 0x43A047),
        NamedColor(name: "orange", hex: 0xFB8C00),
        NamedColor(name: "purple", hex: 0x8E24AA),
    ]
    public static let choiceCount = 3
    /// Right answers needed to win.
    public static let goal = 5

    public private(set) var target: NamedColor
    public private(set) var choices: [NamedColor]
    /// Choices already tried this round. They stay tappable-looking but dimmed.
    public private(set) var wrongPicks: Set<NamedColor> = []
    public private(set) var lastWrongPick: NamedColor?
    public private(set) var stars = 0
    /// True after a right answer, until ``nextRound()``.
    public private(set) var isCelebrating = false

    public var isComplete: Bool { stars >= Self.goal }

    public var statusText: String {
        if isComplete { return "You know your colors! 🎉🎉🎉" }
        if isCelebrating { return "Yes! That's \(target.name)! ⭐" }
        if let wrong = lastWrongPick { return "That's \(wrong.name). Find \(target.name)!" }
        return "Find \(target.name)!"
    }

    public init() {
        var rng = SystemRandomNumberGenerator()
        self.init(using: &rng)
    }

    public init<R: RandomNumberGenerator>(using rng: inout R) {
        (target, choices) = Self.makeRound(avoiding: nil, using: &rng)
    }

    @discardableResult
    public mutating func pick(_ color: NamedColor) -> PickResult {
        guard !isCelebrating, !isComplete, choices.contains(color), !wrongPicks.contains(color) else {
            return .ignored
        }
        guard color == target else {
            wrongPicks.insert(color)
            lastWrongPick = color
            return .tryAgain
        }
        stars += 1
        isCelebrating = true
        lastWrongPick = nil
        return isComplete ? .won : .correct
    }

    public mutating func nextRound() {
        var rng = SystemRandomNumberGenerator()
        nextRound(using: &rng)
    }

    /// Asks for a new color (never the same one twice in a row).
    public mutating func nextRound<R: RandomNumberGenerator>(using rng: inout R) {
        guard isCelebrating, !isComplete else { return }
        (target, choices) = Self.makeRound(avoiding: target, using: &rng)
        wrongPicks = []
        lastWrongPick = nil
        isCelebrating = false
    }

    private static func makeRound<R: RandomNumberGenerator>(
        avoiding previous: NamedColor?,
        using rng: inout R
    ) -> (NamedColor, [NamedColor]) {
        let target = palette.filter { $0 != previous }.randomElement(using: &rng)!
        let others = palette.filter { $0 != target }.shuffled(using: &rng).prefix(choiceCount - 1)
        return (target, ([target] + others).shuffled(using: &rng))
    }
}
