import SwiftUI

/// Flip cards and find pairs. 6 pairs on a 4-wide grid of big cards.
struct MatchingGameView: View {
    @State private var game = MatchingGame()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(game.statusText)
                    .font(Theme.rounded(22, weight: .semibold))
                    .contentTransition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(game.cards) { card in
                        CardButton(card: card) { game.pick(card.id) }
                    }
                }
                .frame(maxWidth: 560)

                Button {
                    game = MatchingGame()
                } label: {
                    Text("🔄 New Game").font(Theme.rounded(22, weight: .semibold)).padding(.horizontal, 20)
                }
                .chunkyButton()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        // Mismatched cards stay up long enough to see, then flip back.
        // Leaving the game cancels this, so nothing fires after unmount.
        .task(id: game.mismatch) {
            guard game.mismatch != nil else { return }
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) { game.hideMismatch() }
        }
    }
}

private struct CardButton: View {
    let card: MatchingGame.Card
    let action: () -> Void

    private var fill: Color {
        if card.isMatched { return Theme.matched }
        return card.isFaceUp ? .white : Theme.accent
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if card.isFaceUp {
                        Text(card.face)
                            .font(.system(size: 56))
                            .minimumScaleFactor(0.4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
        }
        .buttonStyle(ChunkyButtonStyle(
            fill: fill,
            border: card.isMatched ? Theme.green : Theme.ink,
            cornerRadius: 20
        ))
        .accessibilityLabel(card.isFaceUp ? card.face : "Hidden card")
    }
}

#Preview {
    MatchingGameView().background(Theme.background)
}
