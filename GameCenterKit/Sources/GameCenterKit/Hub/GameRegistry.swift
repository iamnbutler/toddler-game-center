import SwiftUI

/// One game in the hub.
public struct GameEntry: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let emoji: String
    public let color: Color
    let makeView: @MainActor @Sendable () -> AnyView

    public init<Content: View>(
        id: String,
        title: String,
        emoji: String,
        color: Color,
        @ViewBuilder view: @escaping @MainActor @Sendable () -> Content
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.color = color
        self.makeView = { AnyView(view()) }
    }
}

/// Single source of truth for the games the hub shows.
/// Add an entry here and the hub renders a tile for it.
public enum GameRegistry {
    public static let games: [GameEntry] = [
        GameEntry(id: "matching", title: "Matching", emoji: "🐻", color: Color(hex: 0xFFD6A5)) {
            MatchingGameView()
        },
        GameEntry(id: "red-light-green-light", title: "Red Light, Green Light", emoji: "🚦", color: Color(hex: 0xA0E7A0)) {
            RedLightGameView()
        },
        GameEntry(id: "balloon-pop", title: "Balloon Pop", emoji: "🎈", color: Color(hex: 0xFFC6D9)) {
            BalloonPopView()
        },
        GameEntry(id: "colors", title: "Colors", emoji: "🎨", color: Color(hex: 0xBDE0FE)) {
            ColorGameView()
        },
        GameEntry(id: "counting", title: "Counting", emoji: "🔢", color: Color(hex: 0xE4C1F9)) {
            CountingGameView()
        },
    ]
}
