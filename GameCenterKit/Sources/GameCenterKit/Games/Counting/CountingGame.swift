/// Rules for the counting game: count the things on screen (1 to 5), then tap
/// the right number out of three. Five right answers wins.
///
/// Tapping a thing counts it, so it can show "1", "2", "3"… in the order it was
/// touched. A value type with no timers: after a right answer the game
/// celebrates and ignores picks until the view calls ``nextRound()``.
public struct CountingGame: Sendable {
    public enum PickResult: Equatable, Sendable {
        case ignored, correct, tryAgain, won
    }

    public static let things = ["🦆", "🍎", "🐢", "🐞", "🚗", "🍓", "🐟", "🌼"]
    public static let range = 1...5
    public static let choiceCount = 3
    /// Right answers needed to win.
    public static let goal = 5

    /// How many things are on screen this round.
    public private(set) var count: Int
    /// The emoji being counted this round.
    public private(set) var thing: String
    /// Numbers to choose from, smallest first.
    public private(set) var choices: [Int]
    /// Indexes of the things the player has counted, in the order they tapped them.
    public private(set) var counted: [Int] = []
    public private(set) var wrongPicks: Set<Int> = []
    public private(set) var stars = 0
    /// True after a right answer, until ``nextRound()``.
    public private(set) var isCelebrating = false

    public var isComplete: Bool { stars >= Self.goal }

    public var statusText: String {
        if isComplete { return "Super counting! 🎉🎉🎉" }
        if isCelebrating { return "Yes! \(count) \(thing)! ⭐" }
        if !wrongPicks.isEmpty { return "Let's count again! Tap each one." }
        return "How many \(thing)?"
    }

    public init() {
        var rng = SystemRandomNumberGenerator()
        self.init(using: &rng)
    }

    public init<R: RandomNumberGenerator>(using rng: inout R) {
        (count, thing, choices) = Self.makeRound(avoiding: nil, using: &rng)
    }

    /// The number shown on a thing, if it has been counted.
    public func number(for index: Int) -> Int? {
        counted.firstIndex(of: index).map { $0 + 1 }
    }

    /// Counts one thing. Returns its number, or nil if it was already counted.
    @discardableResult
    public mutating func countThing(at index: Int) -> Int? {
        guard (0..<count).contains(index), !counted.contains(index) else { return nil }
        counted.append(index)
        return counted.count
    }

    @discardableResult
    public mutating func pick(_ number: Int) -> PickResult {
        guard !isCelebrating, !isComplete, choices.contains(number), !wrongPicks.contains(number) else {
            return .ignored
        }
        guard number == count else {
            wrongPicks.insert(number)
            return .tryAgain
        }
        // Show the answer counted out, left to right.
        counted = Array(0..<count)
        stars += 1
        isCelebrating = true
        return isComplete ? .won : .correct
    }

    public mutating func nextRound() {
        var rng = SystemRandomNumberGenerator()
        nextRound(using: &rng)
    }

    /// A new number of new things (never the same number twice in a row).
    public mutating func nextRound<R: RandomNumberGenerator>(using rng: inout R) {
        guard isCelebrating, !isComplete else { return }
        (count, thing, choices) = Self.makeRound(avoiding: (count, thing), using: &rng)
        counted = []
        wrongPicks = []
        isCelebrating = false
    }

    private static func makeRound<R: RandomNumberGenerator>(
        avoiding previous: (count: Int, thing: String)?,
        using rng: inout R
    ) -> (Int, String, [Int]) {
        let count = range.filter { $0 != previous?.count }.randomElement(using: &rng)!
        let thing = things.filter { $0 != previous?.thing }.randomElement(using: &rng)!
        let others = range.filter { $0 != count }.shuffled(using: &rng).prefix(choiceCount - 1)
        return (count, thing, ([count] + others).sorted())
    }
}
