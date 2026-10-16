import SwiftUI

/// The hub: a grid of big game tiles. Opening a game swaps the whole screen for
/// it, with a big Back button, so there is no navigation chrome to get lost in.
public struct GameCenterView: View {
    private let games: [GameEntry]
    @State private var activeGame: GameEntry?
    @FocusState private var focusedTile: GameEntry.ID?

    public init(games: [GameEntry] = GameRegistry.games) {
        self.games = games
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                if let game = activeGame {
                    // A fresh identity per visit, so each visit starts a new round.
                    game.makeView()
                        .id(game.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    hub
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.light)
        #if os(macOS)
        .frame(minWidth: 640, minHeight: 640)
        #endif
    }

    private var header: some View {
        HStack {
            if let game = activeGame {
                Button(action: closeGame) {
                    Text("← Back").font(Theme.rounded(22, weight: .semibold)).padding(.horizontal, 20)
                }
                .chunkyButton()
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Back to all games")
                Spacer()
                Text("\(game.emoji) \(game.title)").font(Theme.rounded(28))
                Spacer()
                // Balances the Back button so the title stays centered.
                Color.clear.frame(width: 120, height: 1)
            } else {
                Text("🎉 Toddler Game Center").font(Theme.rounded(28))
                Spacer()
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(minHeight: 92)
        .background(Color.white.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) { Theme.accent.frame(height: 4) }
    }

    private var hub: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 20)], spacing: 20) {
                ForEach(games) { game in
                    Button { openGame(game) } label: {
                        VStack(spacing: 12) {
                            Text(game.emoji).font(.system(size: 72))
                            Text(game.title)
                                .font(Theme.rounded(24))
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 220)
                    }
                    .chunkyButton(fill: game.color, cornerRadius: 24, lineWidth: 6)
                    .focused($focusedTile, equals: game.id)
                    .accessibilityLabel(game.title)
                }
            }
            .padding(24)
        }
    }

    private func openGame(_ game: GameEntry) {
        activeGame = game
    }

    private func closeGame() {
        let previous = activeGame
        activeGame = nil
        // Coming back from a game: return keyboard focus to that game's tile.
        Task { @MainActor in focusedTile = previous?.id }
    }
}

#Preview {
    GameCenterView()
}
