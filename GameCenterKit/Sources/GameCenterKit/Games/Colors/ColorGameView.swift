import SwiftUI

/// Shows a color to find, then three big color blobs. Tap the one that matches.
/// The prompt is a swatch as well as a word, so children who can't read yet
/// can play by matching.
struct ColorGameView: View {
    @State private var game: ColorGame

    init(game: ColorGame = ColorGame()) {
        _game = State(initialValue: game)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StarProgress(earned: game.stars, goal: ColorGame.goal)

                prompt

                HStack(spacing: 16) {
                    ForEach(game.choices, id: \.self) { color in
                        ColorChoiceButton(
                            color: color,
                            isWrong: game.wrongPicks.contains(color),
                            isRight: game.isCelebrating && color == game.target
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = game.pick(color) }
                        }
                    }
                }
                .frame(maxWidth: 600)

                PlayAgainButton(title: game.isComplete ? "🔄 Play Again" : "🔄 New Game") {
                    game = ColorGame()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        // A right answer gets a moment of celebration, then the next color.
        // Leaving the game cancels this, so nothing fires after unmount.
        .task(id: game.isCelebrating) {
            guard game.isCelebrating else { return }
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) { game.nextRound() }
        }
    }

    private var prompt: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color(hex: game.target.hex))
                .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 5))
                .frame(width: 90, height: 90)
                .accessibilityHidden(true)
            Text(game.statusText)
                .font(Theme.rounded(30))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .contentTransition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

private struct ColorChoiceButton: View {
    let color: ColorGame.NamedColor
    let isWrong: Bool
    let isRight: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color.hex))
                .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 5))
                .padding(14)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 180)
        }
        .chunkyButton(fill: isRight ? Theme.matched : .white, cornerRadius: 28, lineWidth: isRight ? 6 : 4)
        .cornerBadge {
            if isRight {
                Text("⭐")
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(.white))
                    .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 4))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        // A wrong choice shrinks but keeps its real color: fading it would
        // turn orange into peach, which is no help when learning colors.
        .scaleEffect(isRight ? 1.08 : (isWrong ? 0.8 : 1))
        .shake(isWrong)
        .accessibilityLabel(color.name)
    }
}

#Preview {
    ColorGameView().background(Theme.background)
}
