import CoreGraphics

struct LayoutAttributes: Sendable {
    var frame: CGRect
    var preferredFrame: CGRect?
    var intrinsicFrame: CGRect { preferredFrame ?? frame }
    var zIndex: Int
}
