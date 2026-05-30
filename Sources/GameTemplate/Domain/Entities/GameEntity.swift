import Foundation

typealias EntityID = UUID

protocol GameEntity: Identifiable, Sendable {
    var id: EntityID { get }
    var position: CGPoint { get set }
    var isActive: Bool { get set }
}

struct CGPoint: Sendable, Equatable {
    var x: Double
    var y: Double

    static let zero = CGPoint(x: 0, y: 0)

    init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
