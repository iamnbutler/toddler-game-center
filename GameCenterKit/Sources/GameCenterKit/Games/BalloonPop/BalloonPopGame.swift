/// Rules for Balloon Pop: balloons float up from the bottom and the player taps
/// them to pop them. Balloons that reach the top just float away (no penalty).
/// Pop ten to win.
///
/// A value type with no timers. The view calls ``advance(by:using:)`` every
/// frame with the time that passed. That moves the balloons up, lets the ones at
/// the top float away, and releases new ones from the bottom.
public struct BalloonPopGame: Sendable {
    public struct Balloon: Identifiable, Equatable, Sendable {
        public let id: Int
        /// 0xRRGGBB, so the rules don't depend on SwiftUI.
        public let color: UInt32
        /// Horizontal center: 0 is the left edge of the sky, 1 the right.
        public let x: Double
        /// 0 is just below the bottom of the sky, 1 is just above the top.
        public internal(set) var y: Double
        /// How much of the sky it rises per second.
        public let speed: Double
    }

    public enum PopResult: Equatable, Sendable {
        case ignored, popped, won
    }

    public static let colors: [UInt32] = [0xE53935, 0x1E88E5, 0xFDD835, 0x43A047, 0xFB8C00, 0x8E24AA]
    /// Pops needed to win.
    public static let goal = 10
    /// At most this many balloons in the sky at once.
    public static let maxBalloons = 4
    /// Seconds between new balloons.
    public static let releaseInterval = 0.9...1.6
    /// Slow enough for small hands: 7–11 seconds to cross the sky.
    public static let speedRange = 0.09...0.14
    /// Longest step ``advance(by:using:)`` takes, so a stall (or the app being
    /// in the background) doesn't make every balloon jump away at once.
    public static let maxStep = 0.25

    public private(set) var balloons: [Balloon] = []
    public private(set) var popped = 0
    public private(set) var floatedAway = 0
    private var nextID = 0
    /// The first balloon goes up right away.
    private var untilNextRelease = 0.0

    public var isComplete: Bool { popped >= Self.goal }

    /// The balloon Space pops: the highest one, which would float away first.
    public var nextToPop: Balloon.ID? {
        balloons.max { $0.y < $1.y }?.id
    }

    public var statusText: String {
        if isComplete { return "You popped them all! 🎉🎉🎉" }
        if popped > 0 { return "Pop! 💥 \(popped) of \(Self.goal)" }
        return "Pop the balloons! 🎈"
    }

    public init() {}

    public mutating func advance<R: RandomNumberGenerator>(by seconds: Double, using rng: inout R) {
        guard seconds > 0 else { return }
        let step = min(seconds, Self.maxStep)

        for i in balloons.indices {
            balloons[i].y += balloons[i].speed * step
        }
        let before = balloons.count
        balloons.removeAll { $0.y >= 1 }
        floatedAway += before - balloons.count

        guard !isComplete else { return }
        untilNextRelease -= step
        if untilNextRelease <= 0, balloons.count < Self.maxBalloons {
            release(using: &rng)
            untilNextRelease = Double.random(in: Self.releaseInterval, using: &rng)
        }
    }

    public mutating func advance(by seconds: Double) {
        var rng = SystemRandomNumberGenerator()
        advance(by: seconds, using: &rng)
    }

    /// Pops a balloon. Once the game is won, leftover balloons can still be
    /// popped for fun, but they don't count.
    @discardableResult
    public mutating func pop(_ id: Balloon.ID) -> PopResult {
        guard let index = balloons.firstIndex(where: { $0.id == id }) else { return .ignored }
        balloons.remove(at: index)
        guard !isComplete else { return .popped }
        popped += 1
        return isComplete ? .won : .popped
    }

    private mutating func release<R: RandomNumberGenerator>(using rng: inout R) {
        // Keep a new balloon away from the ones still near the bottom, so
        // they don't overlap. A few tries is plenty.
        let lowBalloons = balloons.filter { $0.y < 0.35 }
        var x = Double.random(in: 0...1, using: &rng)
        for _ in 0..<8 where lowBalloons.contains(where: { abs($0.x - x) < 0.25 }) {
            x = Double.random(in: 0...1, using: &rng)
        }
        balloons.append(Balloon(
            id: nextID,
            color: Self.colors.randomElement(using: &rng)!,
            x: x,
            y: 0,
            speed: Double.random(in: Self.speedRange, using: &rng)
        ))
        nextID += 1
    }
}
