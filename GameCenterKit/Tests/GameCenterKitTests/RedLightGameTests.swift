@testable import GameCenterKit
import Testing

@Suite struct RedLightGameTests {
    @Test func greenTapsMoveForward() {
        var game = RedLightGame()
        #expect(game.tap() == .moved)
        #expect(game.progress == RedLightGame.step)
    }

    @Test func redTapSendsRunnerBackToStart() {
        var game = RedLightGame()
        game.tap()
        game.tap()
        game.switchLight()
        #expect(game.light == .red)
        #expect(game.tap() == .sentBack)
        #expect(game.progress == 0)
        #expect(game.sentBackCount == 1)
    }

    @Test func reachingTheFinishWins() {
        var game = RedLightGame()
        var result = RedLightGame.TapResult.moved
        var taps = 0
        while result == .moved {
            result = game.tap()
            taps += 1
        }
        #expect(result == .won)
        #expect(taps == 13)
        #expect(game.hasWon)
        #expect(game.progress == 1)
        #expect(game.tap() == .ignored)
    }

    @Test func lightStopsSwitchingAfterWin() {
        var game = RedLightGame()
        while game.tap() != .won {}
        game.switchLight()
        #expect(game.light == .green)
    }

    @Test func switchDelaysStayInRange() {
        var rng = SeededGenerator(state: 7)
        var game = RedLightGame()
        for _ in 0..<50 {
            let green = game.nextSwitchDelay(using: &rng)
            #expect(green >= .milliseconds(2500) && green <= .milliseconds(5500))
        }
        game.switchLight()
        for _ in 0..<50 {
            let red = game.nextSwitchDelay(using: &rng)
            #expect(red >= .milliseconds(1500) && red <= .milliseconds(3000))
        }
    }
}
