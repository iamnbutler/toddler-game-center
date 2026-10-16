import SwiftUI

/// Toddler-friendly palette: warm background, dark ink outlines, bright fills.
enum Theme {
    static let background = Color(hex: 0xFFF9E6)
    static let ink = Color(hex: 0x222233)
    static let accent = Color(hex: 0xFF7A59)
    static let green = Color(hex: 0x4CAF50)
    static let red = Color(hex: 0xE53935)
    static let matched = Color(hex: 0xCFE9C8)
    static let tapButton = Color(hex: 0xFFE066)

    static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Big, thick-bordered button that dips when pressed. Used everywhere so every
/// control looks tappable to small hands.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = .white
    var border: Color = Theme.ink
    var cornerRadius: CGFloat = 16
    var lineWidth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonBody(configuration: configuration, style: self)
    }
}

private struct ChunkyButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let style: ChunkyButtonStyle
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
        configuration.label
            .foregroundStyle(Theme.ink)
            .frame(minWidth: 60, minHeight: 60)
            .background(shape.fill(style.fill))
            .overlay(shape.strokeBorder(style.border, lineWidth: style.lineWidth))
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.7)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

extension View {
    func chunkyButton(fill: Color = .white, cornerRadius: CGFloat = 16, lineWidth: CGFloat = 4) -> some View {
        buttonStyle(ChunkyButtonStyle(fill: fill, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
