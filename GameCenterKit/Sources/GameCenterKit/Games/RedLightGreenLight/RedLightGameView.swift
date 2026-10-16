import SwiftUI

/// Tap the big button (or press Space) to move on green. Tapping on red sends
/// the turtle back to the start.
struct RedLightGameView: View {
    @State private var game = RedLightGame()
    /// Bumped on Play Again to restart the light timer for the new round.
    @State private var round = 0
    @State private var showingSentBack = false
    @FocusState private var stageFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            light
            track
            tapButton
            Button(action: playAgain) {
                Text("🔄 Play Again").font(Theme.rounded(22, weight: .semibold)).padding(.horizontal, 20)
            }
            .chunkyButton()
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Space is the tap, wherever focus is in the game. Buttons that have
        // keyboard focus handle Space themselves first, so there's no double tap.
        .focusable()
        .focusEffectDisabled()
        .focused($stageFocused)
        .onKeyPress(.space, phases: .down) { _ in
            // .down only: holding Space is not a stream of taps.
            tap()
            return .handled
        }
        .onAppear { stageFocused = true }
        // The light keeps switching until the round is won. Leaving the game or
        // starting a new round cancels the old loop.
        .task(id: round) {
            while !game.hasWon {
                try? await Task.sleep(for: game.nextSwitchDelay())
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 0.2)) { game.switchLight() }
            }
        }
        .task(id: game.sentBackCount) {
            guard game.sentBackCount > 0 else { return }
            showingSentBack = true
            try? await Task.sleep(for: .milliseconds(900))
            if Task.isCancelled { return }
            showingSentBack = false
        }
    }

    private var light: some View {
        let label = game.hasWon ? "YOU WIN! 🎉" : (game.light == .green ? "GO!" : "STOP!")
        let isGreen = game.hasWon || game.light == .green
        return Text(label)
            .font(Theme.rounded(42, weight: .heavy))
            .foregroundStyle(.white)
            .frame(maxWidth: 500, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isGreen ? Theme.green : Theme.red)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: 6)
            )
            .accessibilityAddTraits(.updatesFrequently)
    }

    private var track: some View {
        GeometryReader { proxy in
            let runnerSize: CGFloat = 72
            let travel = max(0, proxy.size.width - runnerSize - 16)
            ZStack(alignment: .leading) {
                Text("🏁")
                    .font(.system(size: 48))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                Text(game.hasWon ? "🐇" : "🐢")
                    .font(.system(size: 56))
                    .frame(width: runnerSize)
                    .offset(x: 8 + travel * game.progress)
                    .animation(.easeOut(duration: 0.15), value: game.progress)
                    .accessibilityLabel("Runner, \(Int(game.progress * 100)) percent of the way")
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 90)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.ink, style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
        )
    }

    private var tapButton: some View {
        let label = game.hasWon ? "🏆 Finished!" : (showingSentBack ? "⛔ Back to start!" : "👆 TAP TO GO")
        return Button(action: tap) {
            Text(label)
                .font(Theme.rounded(32, weight: .heavy))
                .frame(maxWidth: .infinity)
                .padding(28)
        }
        .chunkyButton(fill: Theme.tapButton, cornerRadius: 24, lineWidth: 6)
        .disabled(game.hasWon)
    }

    private func tap() {
        game.tap()
    }

    private func playAgain() {
        game = RedLightGame()
        showingSentBack = false
        round += 1
        // Put focus back on the stage so the next Space is a tap, not another restart.
        stageFocused = true
    }
}

#Preview {
    RedLightGameView().background(Theme.background)
}
