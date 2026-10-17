import SwiftUI

/// A row of stars showing progress toward a goal: ⭐⭐⭐☆☆.
struct StarProgress: View {
    let earned: Int
    let goal: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<goal, id: \.self) { index in
                Text(index < earned ? "⭐" : "☆")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.ink.opacity(0.35))
                    .scaleEffect(index < earned ? 1 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: earned)
            }
        }
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(earned) of \(goal) stars")
    }
}

/// Side-to-side wiggle for a wrong answer. Animate `progress` from 0 to 1 to
/// play one shake; it ends where it started.
struct Shake: GeometryEffect {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(progress * .pi * 6), y: 0))
    }
}

extension View {
    /// Shakes once when `trigger` becomes true.
    func shake(_ trigger: Bool) -> some View {
        modifier(Shake(progress: trigger ? 1 : 0))
            .animation(.easeInOut(duration: 0.4), value: trigger)
    }
}

extension View {
    /// A round badge on the top-right corner, drawn over the button's border
    /// rather than under it. Taps go through to the button.
    func cornerBadge<Badge: View>(@ViewBuilder _ badge: () -> Badge) -> some View {
        overlay(alignment: .topTrailing) {
            badge()
                .offset(x: 10, y: -10)
                .allowsHitTesting(false)
        }
    }
}

/// The "🔄 Play Again" button every game ends with.
struct PlayAgainButton: View {
    var title = "🔄 Play Again"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(Theme.rounded(22, weight: .semibold)).padding(.horizontal, 20)
        }
        .chunkyButton()
    }
}
