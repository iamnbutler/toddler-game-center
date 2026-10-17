@testable import GameCenterKit
import Testing

@Suite struct BalloonPopGameTests {
    /// Runs the game for `seconds` in small frames, like the view does.
    func run(_ game: inout BalloonPopGame, for seconds: Double, rng: inout SeededGenerator) {
        var elapsed = 0.0
        while elapsed < seconds {
            game.advance(by: 0.05, using: &rng)
            elapsed += 0.05
        }
    }

    @Test func firstBalloonGoesUpRightAway() {
        var rng = SeededGenerator(state: 1)
        var game = BalloonPopGame()
        #expect(game.balloons.isEmpty)
        #expect(game.statusText == "Pop the balloons! 🎈")
        game.advance(by: 0.01, using: &rng)
        #expect(game.balloons.count == 1)
        let balloon = game.balloons[0]
        #expect((0...1).contains(balloon.x))
        #expect(BalloonPopGame.speedRange.contains(balloon.speed))
        #expect(BalloonPopGame.colors.contains(balloon.color))
    }

    @Test func balloonsRiseAtTheirOwnSpeed() {
        var rng = SeededGenerator(state: 2)
        var game = BalloonPopGame()
        game.advance(by: 0.01, using: &rng)
        let start = game.balloons[0]
        game.advance(by: 0.2, using: &rng)
        let moved = game.balloons.first { $0.id == start.id }!
        #expect(abs(moved.y - (start.y + start.speed * 0.2)) < 1e-9)
    }

    @Test func neverMoreThanTheMaximumInTheSky() {
        var rng = SeededGenerator(state: 3)
        var game = BalloonPopGame()
        for _ in 0..<2000 {
            game.advance(by: 0.05, using: &rng)
            #expect(game.balloons.count <= BalloonPopGame.maxBalloons)
        }
        #expect(game.floatedAway > 0)
    }

    @Test func balloonsAtTheTopFloatAway() {
        var rng = SeededGenerator(state: 4)
        var game = BalloonPopGame()
        game.advance(by: 0.01, using: &rng)
        let first = game.balloons[0].id
        // The slowest balloon crosses the sky in about 11 seconds.
        run(&game, for: 12, rng: &rng)
        #expect(!game.balloons.contains { $0.id == first })
        #expect(game.floatedAway >= 1)
        #expect(game.popped == 0)
    }

    @Test func longStallsAreCapped() {
        var rng = SeededGenerator(state: 5)
        var game = BalloonPopGame()
        game.advance(by: 0.01, using: &rng)
        let start = game.balloons[0]
        game.advance(by: 30, using: &rng)
        let moved = game.balloons.first { $0.id == start.id }!
        #expect(abs(moved.y - (start.y + start.speed * BalloonPopGame.maxStep)) < 1e-9)
    }

    @Test func poppingRemovesTheBalloonAndCounts() {
        var rng = SeededGenerator(state: 6)
        var game = BalloonPopGame()
        game.advance(by: 0.01, using: &rng)
        let id = game.balloons[0].id
        #expect(game.pop(id) == .popped)
        #expect(game.popped == 1)
        #expect(game.balloons.isEmpty)
        #expect(game.statusText == "Pop! 💥 1 of \(BalloonPopGame.goal)")
        #expect(game.pop(id) == .ignored)
        #expect(game.popped == 1)
    }

    @Test func nextToPopIsTheHighestBalloon() {
        var rng = SeededGenerator(state: 7)
        var game = BalloonPopGame()
        #expect(game.nextToPop == nil)
        run(&game, for: 4, rng: &rng)
        #expect(game.balloons.count >= 2)
        let highest = game.balloons.max { $0.y < $1.y }!
        #expect(game.nextToPop == highest.id)
    }

    @Test func poppingTheGoalWinsAndStopsNewBalloons() {
        var rng = SeededGenerator(state: 8)
        var game = BalloonPopGame()
        // Pop all but one, as soon as each balloon appears.
        while game.popped < BalloonPopGame.goal - 1 {
            game.advance(by: 0.05, using: &rng)
            if let id = game.nextToPop { #expect(game.pop(id) == .popped) }
        }
        // Let two balloons up, so one is left over after the winning pop.
        while game.balloons.count < 2 { game.advance(by: 0.05, using: &rng) }
        #expect(game.pop(game.nextToPop!) == .won)
        #expect(game.isComplete)
        #expect(game.statusText == "You popped them all! 🎉🎉🎉")

        // Leftovers can be popped for fun, but don't count.
        #expect(game.pop(game.nextToPop!) == .popped)
        #expect(game.popped == BalloonPopGame.goal)

        // No new balloons after the win.
        run(&game, for: 5, rng: &rng)
        #expect(game.balloons.isEmpty)
    }
}
