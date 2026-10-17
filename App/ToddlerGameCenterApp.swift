import GameCenterKit
import SwiftUI

@main
struct ToddlerGameCenterApp: App {
    var body: some Scene {
        WindowGroup {
            GameCenterView()
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 780)
        #endif
    }
}
