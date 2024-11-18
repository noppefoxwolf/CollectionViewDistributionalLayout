import CoreGraphics

struct LayoutAttributes: Sendable {
    var distribution: Distribution?
    var x: CGFloat
    var width: CGFloat
    var height: CGFloat
    var zIndex: Int
}
