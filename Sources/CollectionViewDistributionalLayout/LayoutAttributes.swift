import CoreGraphics

struct LayoutAttributes: Sendable {
    var distribution: Distribution?
    var frame: CGRect
    var preferredFrame: CGRect?
    var zIndex: Int
}
