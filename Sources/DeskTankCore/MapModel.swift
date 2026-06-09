import Foundation

public struct MapModel: Equatable, Sendable {
    public let bounds: Rect
    public let obstacles: [Obstacle]

    public init(bounds: Rect, obstacles: [Obstacle] = []) {
        self.bounds = bounds
        self.obstacles = obstacles
    }

    public func replacingDesktopItems(_ items: [DesktopItem]) -> MapModel {
        let nextObstacles = items
            .map { Obstacle(id: $0.id, frame: $0.frame, label: $0.name, isDirectory: $0.isDirectory) }
            .filter { bounds.intersects($0.frame) }
        return MapModel(bounds: bounds, obstacles: nextObstacles)
    }

    public func isBlocked(_ frame: Rect) -> Bool {
        !bounds.contains(frame) || obstacles.contains { $0.frame.intersects(frame) }
    }

    public func nearestOpenFrame(to frame: Rect, step: Double = 12, maxRadius: Int = 40) -> Rect {
        if !isBlocked(frame) {
            return frame
        }

        for radius in 1...maxRadius {
            let offsets = (-radius...radius).flatMap { x in
                (-radius...radius).map { y in Point(x: Double(x) * step, y: Double(y) * step) }
            }

            if let candidate = offsets
                .map({ Rect(origin: frame.origin.offset(dx: $0.x, dy: $0.y), size: frame.size) })
                .first(where: { !isBlocked($0) }) {
                return candidate
            }
        }

        return bounds.insetBy(dx: frame.size.width, dy: frame.size.height)
    }

    public func firstOpenFrame(size: Size, preferred: [Point]) -> Rect? {
        preferred
            .map { Rect(origin: $0, size: size) }
            .first { !isBlocked($0) }
    }
}
