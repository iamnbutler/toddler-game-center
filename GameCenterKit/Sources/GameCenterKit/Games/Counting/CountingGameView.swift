import SwiftUI

/// Count the things, then tap the number. Tapping a thing counts it out loud
/// on screen ("1", "2", "3"). Number keys 1–5 answer too.
struct CountingGameView: View {
    @State private var game: CountingGame
    @FocusState private var stageFocused: Bool

    init(game: CountingGame = CountingGame()) {
        _game = State(initialValue: game)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StarProgress(earned: game.stars, goal: CountingGame.goal)

                Text(game.statusText)
                    .font(Theme.rounded(30))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)

                things

                HStack(spacing: 16) {
                    ForEach(game.choices, id: \.self) { number in
                        NumberButton(
                            number: number,
                            isWrong: game.wrongPicks.contains(number),
                            isRight: game.isCelebrating && number == game.count
                        ) { pick(number) }
                    }
                }
                .frame(maxWidth: 560)

                PlayAgainButton(title: game.isComplete ? "🔄 Play Again" : "🔄 New Game") {
                    game = CountingGame()
                    stageFocused = true
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        // Number keys answer, wherever focus is in the game.
        .focusable()
        .focusEffectDisabled()
        .focused($stageFocused)
        .onKeyPress(characters: .decimalDigits, phases: .down) { press in
            guard let number = Int(press.characters), game.choices.contains(number) else { return .ignored }
            pick(number)
            return .handled
        }
        .onAppear { stageFocused = true }
        // A right answer gets a moment of celebration, then the next round.
        // Leaving the game cancels this, so nothing fires after unmount.
        .task(id: game.isCelebrating) {
            guard game.isCelebrating else { return }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) { game.nextRound() }
        }
    }

    /// The things to count, in one row so they're easy to count left to right.
    private var things: some View {
        HStack(spacing: 10) {
            ForEach(0..<game.count, id: \.self) { index in
                ThingButton(thing: game.thing, number: game.number(for: index)) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = game.countThing(at: index) }
                }
            }
        }
        .frame(maxWidth: 600)
        // A new round swaps the whole row, rather than morphing the old one.
        // Rounds never repeat the count or the thing, so this changes every round.
        .id("\(game.thing)-\(game.count)")
        .transition(.opacity)
    }

    private func pick(_ number: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = game.pick(number) }
    }
}

private struct ThingButton: View {
    let thing: String
    let number: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Text(thing)
                        .font(.system(size: 60))
                        .minimumScaleFactor(0.3)
                        .padding(8)
                }
        }
        .chunkyButton(fill: number == nil ? .white : Theme.matched, cornerRadius: 20)
        .cornerBadge {
            if let number {
                Text("\(number)")
                    .font(Theme.rounded(24, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.accent))
                    .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 3))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: 110)
        .accessibilityLabel(number.map { "\(thing), number \($0)" } ?? thing)
    }
}

private struct NumberButton: View {
    let number: Int
    let isWrong: Bool
    let isRight: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(Theme.rounded(64, weight: .heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .chunkyButton(fill: isRight ? Theme.matched : Theme.tapButton, cornerRadius: 24, lineWidth: isRight ? 6 : 4)
        .scaleEffect(isRight ? 1.08 : (isWrong ? 0.85 : 1))
        .opacity(isWrong ? 0.4 : 1)
        .shake(isWrong)
        .accessibilityLabel("\(number)")
    }
}

#Preview {
    CountingGameView().background(Theme.background)
}
