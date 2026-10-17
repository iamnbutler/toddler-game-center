/// Rules for Red Light, Green Light: taps move the runner on green and send it
/// back to the start on red.
///
/// A value type with no timers. The view decides when the light switches,
/// using ``nextSwitchDelay(using:)`` for how long the current light lasts.
public struct RedLightGame: Sendable {
    public enum Light: Sendable { case green, red }

    public enum TapResult: Equatable, Sendable {
        case ignored, moved, won, sentBack
    }

    /// How far one green tap moves the runner, as a fraction of the track.
    public static let step = 0.08

    public private(set) var light = Light.green
    /// 0 is the start line, 1 is the finish.
    public private(set) var progress = 0.0
    public private(set) var hasWon = false
    /// Counts red-light taps, so the view can react to each one.
    public private(set) var sentBackCount = 0

    public init() {}

    @discardableResult
    public mutating func tap() -> TapResult {
        guard !hasWon else { return .ignored }
        switch light {
        case .green:
            progress = min(1, progress + Self.step)
            if progress >= 1 {
                hasWon = true
                return .won
            }
            return .moved
        case .red:
            progress = 0
            sentBackCount += 1
            return .sentBack
        }
    }

    public mutating func switchLight() {
        guard !hasWon else { return }
        light = light == .green ? .red : .green
    }

    /// Green lasts 2.5–5.5 s, red 1.5–3 s.
    public func nextSwitchDelay<R: RandomNumberGenerator>(using rng: inout R) -> Duration {
        let seconds = switch light {
        case .green: Double.random(in: 2.5...5.5, using: &rng)
        case .red: Double.random(in: 1.5...3.0, using: &rng)
        }
        return .milliseconds(Int(seconds * 1000))
    }

    public func nextSwitchDelay() -> Duration {
        var rng = SystemRandomNumberGenerator()
        return nextSwitchDelay(using: &rng)
    }
}
