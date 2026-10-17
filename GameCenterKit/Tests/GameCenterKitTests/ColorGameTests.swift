@testable import GameCenterKit
import Testing

@Suite struct ColorGameTests {
    func makeGame(seed: UInt64 = 1) -> ColorGame {
        var rng = SeededGenerator(state: seed)
        return ColorGame(using: &rng)
    }

    func wrongChoice(in game: ColorGame) -> ColorGame.NamedColor {
        game.choices.first { $0 != game.target }!
    }

    @Test func dealsThreeDifferentChoicesIncludingTheTarget() {
        for seed in 0..<50 {
            let game = makeGame(seed: UInt64(seed))
            #expect(game.choices.count == ColorGame.choiceCount)
            #expect(Set(game.choices).count == ColorGame.choiceCount)
            #expect(game.choices.contains(game.target))
            #expect(game.statusText == "Find \(game.target.name)!")
        }
    }

    @Test func rightPickEarnsAStarAndCelebrates() {
        var game = makeGame()
        #expect(game.pick(game.target) == .correct)
        #expect(game.stars == 1)
        #expect(game.isCelebrating)
        #expect(game.statusText == "Yes! That's \(game.target.name)! ⭐")
        // No double-scoring while celebrating.
        #expect(game.pick(game.target) == .ignored)
        #expect(game.stars == 1)
    }

    @Test func wrongPickNamesTheColorAndCanBeRetried() {
        var game = makeGame()
        let wrong = wrongChoice(in: game)
        #expect(game.pick(wrong) == .tryAgain)
        #expect(game.wrongPicks == [wrong])
        #expect(game.stars == 0)
        #expect(game.statusText == "That's \(wrong.name). Find \(game.target.name)!")
        #expect(game.pick(wrong) == .ignored)
        #expect(game.pick(game.target) == .correct)
    }

    @Test func colorsNotOnScreenAreIgnored() {
        var game = makeGame()
        let offScreen = ColorGame.palette.first { !game.choices.contains($0) }!
        #expect(game.pick(offScreen) == .ignored)
    }

    @Test func nextRoundAsksForADifferentColor() {
        var rng = SeededGenerator(state: 9)
        var game = ColorGame(using: &rng)
        for _ in 0..<(ColorGame.goal - 1) {
            let previous = game.target
            game.pick(game.target)
            game.nextRound(using: &rng)
            #expect(game.target != previous)
            #expect(!game.isCelebrating)
            #expect(game.wrongPicks.isEmpty)
        }
    }

    @Test func nextRoundWaitsForARightAnswer() {
        var rng = SeededGenerator(state: 3)
        var game = ColorGame(using: &rng)
        let target = game.target
        game.nextRound(using: &rng)
        #expect(game.target == target)
    }

    @Test func fiveRightAnswersWin() {
        var game = makeGame()
        for round in 1...ColorGame.goal {
            let result = game.pick(game.target)
            #expect(result == (round == ColorGame.goal ? .won : .correct))
            game.nextRound()
        }
        #expect(game.isComplete)
        #expect(game.statusText == "You know your colors! 🎉🎉🎉")
        #expect(game.pick(game.target) == .ignored)
    }
}
