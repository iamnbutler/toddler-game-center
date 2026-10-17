import SwiftUI

/// Balloons float up the sky; touch one to pop it. Space pops the highest one.
struct BalloonPopView: View {
    @State private var game: BalloonPopGame
    /// Bumped on Play Again to restart the frame loop for the new round.
    @State private var round = 0
    /// Short-lived "💥" marks where balloons were popped.
    @State private var bursts: [Burst] = []
    @FocusState private var stageFocused: Bool

    private struct Burst: Identifiable {
        let id: Int
        let x: Double
        let y: Double
        let color: UInt32
        let time: ContinuousClock.Instant
    }

    private static let balloonWidth: CGFloat = 90
    private static let balloonHeight: CGFloat = 156
    private static let burstLifetime = Duration.milliseconds(450)

    init(game: BalloonPopGame = BalloonPopGame()) {
        _game = State(initialValue: game)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(game.statusText)
                .font(Theme.rounded(28))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.updatesFrequently)

            sky

            PlayAgainButton(title: game.isComplete ? "🔄 Play Again" : "🔄 New Game", action: playAgain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Space pops a balloon, wherever focus is in the game.
        .focusable()
        .focusEffectDisabled()
        .focused($stageFocused)
        .onKeyPress(.space, phases: .down) { _ in
            if let id = game.nextToPop { pop(id) }
            return .handled
        }
        .onAppear { stageFocused = true }
        // The frame loop: moves balloons and releases new ones until the round
        // is won and the sky is empty. Leaving the game or starting a new round
        // cancels it.
        .task(id: round) {
            let clock = ContinuousClock()
            var last = clock.now
            while !Task.isCancelled, !(game.isComplete && game.balloons.isEmpty && bursts.isEmpty) {
                try? await Task.sleep(for: .milliseconds(16))
                let now = clock.now
                game.advance(by: (now - last).seconds)
                bursts.removeAll { now - $0.time > Self.burstLifetime }
                last = now
            }
        }
    }

    private var sky: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                ForEach(game.balloons) { balloon in
                    BalloonView(color: Color(hex: balloon.color))
                        .frame(width: Self.balloonWidth, height: Self.balloonHeight)
                        // Pop on touch down, not release: the balloon is moving,
                        // and small fingers press rather than tap.
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { _ in pop(balloon.id) })
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Balloon")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { pop(balloon.id) }
                        .position(position(of: balloon.x, balloon.y, in: size))
                }
                ForEach(bursts) { burst in
                    BurstView(color: Color(hex: burst.color))
                        .position(position(of: burst.x, burst.y, in: size))
                        .allowsHitTesting(false)
                }
                if game.isComplete {
                    Text("🎉")
                        .font(.system(size: 120))
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(hex: 0xCDEBFF)))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.ink, lineWidth: 6))
        .frame(maxWidth: 800, minHeight: 300, maxHeight: .infinity)
    }

    /// Where a balloon's center is drawn. At y = 0 it sits just below the sky,
    /// at y = 1 just above it, so balloons drift in and out of view.
    private func position(of x: Double, _ y: Double, in size: CGSize) -> CGPoint {
        let inset = Self.balloonWidth / 2 + 8
        let travel = size.height + Self.balloonHeight
        return CGPoint(
            x: inset + max(0, size.width - inset * 2) * x,
            y: size.height + Self.balloonHeight / 2 - travel * y
        )
    }

    private func pop(_ id: BalloonPopGame.Balloon.ID) {
        guard let balloon = game.balloons.first(where: { $0.id == id }) else { return }
        let result = withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { game.pop(id) }
        guard result != .ignored else { return }
        bursts.append(Burst(
            id: balloon.id,
            x: balloon.x,
            y: balloon.y,
            color: balloon.color,
            time: .now
        ))
    }

    private func playAgain() {
        game = BalloonPopGame()
        bursts = []
        round += 1
        // Put focus back on the stage so the next Space pops, not another restart.
        stageFocused = true
    }
}

/// A round balloon with a shine, a knot, and a string.
private struct BalloonView: View {
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Ellipse()
                .fill(color)
                .overlay(alignment: .topLeading) {
                    Ellipse()
                        .fill(.white.opacity(0.55))
                        .frame(width: 16, height: 28)
                        .rotationEffect(.degrees(25))
                        .offset(x: 20, y: 18)
                }
                .overlay(Ellipse().strokeBorder(Theme.ink, lineWidth: 4))
                .frame(height: 110)
            Knot()
                .fill(color)
                .overlay(Knot().stroke(Theme.ink, lineWidth: 3))
                .frame(width: 18, height: 10)
            Rectangle()
                .fill(Theme.ink)
                .frame(width: 2)
        }
    }
}

private struct Knot: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

/// A quick "💥" that grows and fades where a balloon popped.
private struct BurstView: View {
    let color: Color
    @State private var expanded = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(color, lineWidth: 8)
                .frame(width: 90, height: 90)
            Text("💥").font(.system(size: 64))
        }
        .scaleEffect(expanded ? 1.5 : 0.6)
        .opacity(expanded ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { expanded = true }
        }
        // Lift the burst up to the round part of the balloon (above the string).
        .offset(y: -23)
    }
}

private extension Duration {
    var seconds: Double {
        let parts = components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}

#Preview("Mid-game") {
    var game = BalloonPopGame()
    for _ in 0..<120 { game.advance(by: 0.05) }
    return BalloonPopView(game: game).background(Theme.background)
}
