@testable import GameCenterKit
import Testing

/// Deterministic generator so shuffles are repeatable in tests.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite struct MatchingGameTests {
    func makeGame() -> MatchingGame {
        var rng = SeededGenerator(state: 42)
        return MatchingGame(using: &rng)
    }

    func pair(in game: MatchingGame, face: String) -> (Int, Int) {
        let ids = game.cards.filter { $0.face == face }.map(\.id)
        return (ids[0], ids[1])
    }

    func mismatchedPair(in game: MatchingGame) -> (Int, Int) {
        let first = game.cards[0]
        let other = game.cards.first { $0.face != first.face }!
        return (first.id, other.id)
    }

    @Test func dealsTwoOfEachFace() {
        let game = makeGame()
        #expect(game.cards.count == 12)
        #expect(game.pairCount == 6)
        for face in MatchingGame.defaultFaces {
            #expect(game.cards.filter { $0.face == face }.count == 2)
        }
        #expect(game.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
        #expect(game.statusText == "Find the pairs! 🎈")
    }

    @Test func matchingPairStaysFaceUp() {
        var game = makeGame()
        let (a, b) = pair(in: game, face: "🐶")
        #expect(game.pick(a) == .firstCard)
        #expect(game.pick(b) == .match)
        #expect(game.matchedPairs == 1)
        #expect(game.cards.filter(\.isMatched).map(\.id).sorted() == [a, b].sorted())
        #expect(game.statusText == "Great job! ⭐ (1/6)")
        #expect(!game.isLocked)
    }

    @Test func mismatchLocksUntilHidden() {
        var game = makeGame()
        let (a, b) = mismatchedPair(in: game)
        game.pick(a)
        #expect(game.pick(b) == .mismatch)
        #expect(game.isLocked)

        let third = game.cards.first { !$0.isFaceUp }!.id
        #expect(game.pick(third) == .ignored)

        game.hideMismatch()
        #expect(!game.isLocked)
        #expect(game.cards.allSatisfy { !$0.isFaceUp })
        #expect(game.pick(third) == .firstCard)
    }

    @Test func pickingTheSameCardTwiceIsIgnored() {
        var game = makeGame()
        let id = game.cards[0].id
        #expect(game.pick(id) == .firstCard)
        #expect(game.pick(id) == .ignored)
    }

    @Test func matchedCardsCannotBePickedAgain() {
        var game = makeGame()
        let (a, b) = pair(in: game, face: "🐼")
        game.pick(a)
        game.pick(b)
        #expect(game.pick(a) == .ignored)
    }

    @Test func findingEveryPairCompletesTheGame() {
        var game = makeGame()
        for face in MatchingGame.defaultFaces {
            let (a, b) = pair(in: game, face: face)
            game.pick(a)
            game.pick(b)
        }
        #expect(game.isComplete)
        #expect(game.statusText == "You did it! 🎉🎉🎉")
    }
}
