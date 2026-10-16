/// Rules for the matching game: flip two cards, keep them if they match.
///
/// A value type with no timers. When two cards don't match the game locks
/// until the view calls ``hideMismatch()``, so the view owns the pause.
public struct MatchingGame: Sendable {
    public static let defaultFaces = ["🐶", "🐱", "🐰", "🐼", "🦊", "🐸"]

    public struct Card: Identifiable, Equatable, Sendable {
        public let id: Int
        public let face: String
        public internal(set) var isFaceUp = false
        public internal(set) var isMatched = false
    }

    public enum PickResult: Equatable, Sendable {
        case ignored, firstCard, match, mismatch
    }

    public private(set) var cards: [Card]
    public private(set) var matchedPairs = 0
    /// Two face-up cards waiting to be turned back over. Picks are ignored meanwhile.
    public private(set) var mismatch: [Card.ID]?
    private var firstPick: Card.ID?

    public var pairCount: Int { cards.count / 2 }
    public var isComplete: Bool { matchedPairs == pairCount }
    public var isLocked: Bool { mismatch != nil }

    public var statusText: String {
        if isComplete { return "You did it! 🎉🎉🎉" }
        if matchedPairs > 0 { return "Great job! ⭐ (\(matchedPairs)/\(pairCount))" }
        return "Find the pairs! 🎈"
    }

    public init(faces: [String] = defaultFaces) {
        var rng = SystemRandomNumberGenerator()
        self.init(faces: faces, using: &rng)
    }

    public init<R: RandomNumberGenerator>(faces: [String] = defaultFaces, using rng: inout R) {
        cards = (faces + faces)
            .shuffled(using: &rng)
            .enumerated()
            .map { Card(id: $0.offset, face: $0.element) }
    }

    @discardableResult
    public mutating func pick(_ id: Card.ID) -> PickResult {
        guard !isLocked, let index = cards.firstIndex(where: { $0.id == id }) else { return .ignored }
        guard !cards[index].isFaceUp, !cards[index].isMatched else { return .ignored }
        cards[index].isFaceUp = true

        guard let first = firstPick, let firstIndex = cards.firstIndex(where: { $0.id == first }) else {
            firstPick = id
            return .firstCard
        }
        firstPick = nil

        if cards[firstIndex].face == cards[index].face {
            cards[firstIndex].isMatched = true
            cards[index].isMatched = true
            matchedPairs += 1
            return .match
        }
        mismatch = [first, id]
        return .mismatch
    }

    /// Turns a mismatched pair face down again and unlocks the board.
    public mutating func hideMismatch() {
        guard let ids = mismatch else { return }
        for i in cards.indices where ids.contains(cards[i].id) {
            cards[i].isFaceUp = false
        }
        mismatch = nil
    }
}
