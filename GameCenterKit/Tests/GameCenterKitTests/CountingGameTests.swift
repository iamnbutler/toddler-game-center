@testable import GameCenterKit
import Testing

@Suite struct CountingGameTests {
    func makeGame(seed: UInt64 = 1) -> CountingGame {
        var rng = SeededGenerator(state: seed)
        return CountingGame(using: &rng)
    }

    @Test func dealsSortedChoicesIncludingTheAnswer() {
        for seed in 0..<50 {
            let game = makeGame(seed: UInt64(seed))
            #expect(CountingGame.range.contains(game.count))
            #expect(CountingGame.things.contains(game.thing))
            #expect(game.choices.count == CountingGame.choiceCount)
            #expect(game.choices == game.choices.sorted())
            #expect(Set(game.choices).count == CountingGame.choiceCount)
            #expect(game.choices.contains(game.count))
            #expect(game.choices.allSatisfy(CountingGame.range.contains))
        }
    }

    @Test func tappingThingsNumbersThemInOrder() {
        var game = makeGame(seed: 4)
        // Find a round with at least two things.
        var seed: UInt64 = 4
        while game.count < 2 {
            seed += 1
            game = makeGame(seed: seed)
        }
        let last = game.count - 1
        #expect(game.countThing(at: last) == 1)
        #expect(game.countThing(at: 0) == 2)
        #expect(game.number(for: last) == 1)
        #expect(game.number(for: 0) == 2)
        #expect(game.countThing(at: last) == nil)
        #expect(game.countThing(at: game.count) == nil)
    }

    @Test func rightAnswerCountsEverythingLeftToRight() {
        var game = makeGame()
        game.countThing(at: game.count - 1)
        #expect(game.pick(game.count) == .correct)
        #expect(game.stars == 1)
        #expect(game.isCelebrating)
        #expect(game.counted == Array(0..<game.count))
        #expect(game.number(for: 0) == 1)
        #expect(game.statusText == "Yes! \(game.count) \(game.thing)! ⭐")
        #expect(game.pick(game.count) == .ignored)
    }

    @Test func wrongAnswerCanBeRetried() {
        var game = makeGame()
        let wrong = game.choices.first { $0 != game.count }!
        #expect(game.pick(wrong) == .tryAgain)
        #expect(game.wrongPicks == [wrong])
        #expect(game.pick(wrong) == .ignored)
        #expect(game.statusText == "Let's count again! Tap each one.")
        #expect(game.pick(game.count) == .correct)
    }

    @Test func numbersNotOfferedAreIgnored() {
        var game = makeGame()
        let notOffered = CountingGame.range.first { !game.choices.contains($0) }!
        #expect(game.pick(notOffered) == .ignored)
        #expect(game.pick(9) == .ignored)
    }

    @Test func nextRoundChangesTheCountAndClearsTaps() {
        var rng = SeededGenerator(state: 11)
        var game = CountingGame(using: &rng)
        for _ in 0..<(CountingGame.goal - 1) {
            let previous = (game.count, game.thing)
            game.pick(game.count)
            game.nextRound(using: &rng)
            #expect(game.count != previous.0)
            #expect(game.thing != previous.1)
            #expect(game.counted.isEmpty)
            #expect(game.wrongPicks.isEmpty)
            #expect(!game.isCelebrating)
        }
    }

    @Test func fiveRightAnswersWin() {
        var game = makeGame()
        for round in 1...CountingGame.goal {
            #expect(game.pick(game.count) == (round == CountingGame.goal ? .won : .correct))
            game.nextRound()
        }
        #expect(game.isComplete)
        #expect(game.statusText == "Super counting! 🎉🎉🎉")
    }
}
