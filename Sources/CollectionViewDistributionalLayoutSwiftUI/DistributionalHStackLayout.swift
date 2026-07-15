import SwiftUI
import CollectionViewDistributionalLayout

/// A horizontal layout that distributes subviews within a viewport.
///
/// The layout keeps ideal widths when the content does not fit. When all
/// ideal widths fit, it uses equal widths when possible and otherwise keeps
/// the ideal-width ratios.
public struct DistributionalHStackLayout: Layout {
    public var spacing: CGFloat
    public var horizontalInset: CGFloat
    public var viewportWidth: CGFloat

    public init(
        viewportWidth: CGFloat,
        spacing: CGFloat = 10,
        horizontalInset: CGFloat = 20
    ) {
        self.spacing = max(0, spacing)
        self.horizontalInset = max(0, horizontalInset)
        self.viewportWidth = max(0, viewportWidth)
    }

    public struct Cache {
        fileprivate var sizes: [CGSize] = []
        fileprivate var widths: [CGFloat] = []
        fileprivate var distribution: Distribution = .fill
    }

    public func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        cache.sizes = sizes

        guard !sizes.isEmpty else {
            cache.widths = []
            cache.distribution = .fill
            return .zero
        }

        let totalSpacing = spacing * CGFloat(sizes.count - 1)
        let intrinsicItemWidth = sizes.reduce(0) { $0 + $1.width }
        let intrinsicWidth =
            horizontalInset * 2 + totalSpacing + intrinsicItemWidth
        let availableItemWidth = max(
            viewportWidth - horizontalInset * 2 - totalSpacing,
            0
        )

        if intrinsicWidth > viewportWidth {
            cache.distribution = .fill
            cache.widths = sizes.map(\.width)
        } else {
            let equalItemWidth = availableItemWidth / CGFloat(sizes.count)
            let maxItemWidth = sizes.map(\.width).max() ?? 0

            if maxItemWidth <= equalItemWidth {
                cache.distribution = .fillEqually
                cache.widths = Array(
                    repeating: equalItemWidth,
                    count: sizes.count
                )
            } else if intrinsicItemWidth > 0 {
                cache.distribution = .fillProportionally
                cache.widths = sizes.map {
                    availableItemWidth * $0.width / intrinsicItemWidth
                }
            } else {
                cache.distribution = .fillEqually
                cache.widths = Array(
                    repeating: equalItemWidth,
                    count: sizes.count
                )
            }
        }

        let height = sizes.map(\.height).max() ?? 0
        let contentWidth = cache.distribution == .fill
            ? intrinsicWidth
            : viewportWidth

        return CGSize(width: contentWidth, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        var x = bounds.minX + horizontalInset

        for (index, subview) in subviews.enumerated() {
            guard index < cache.widths.count,
                  index < cache.sizes.count else { continue }

            let width = cache.widths[index]
            let height = cache.sizes[index].height
            let y = bounds.midY - height / 2

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: height)
            )

            x += width
            if index < subviews.count - 1 {
                x += spacing
            }
        }
    }
}
