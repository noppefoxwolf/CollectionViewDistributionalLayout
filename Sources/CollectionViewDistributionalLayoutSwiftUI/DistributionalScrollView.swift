import SwiftUI

/// A horizontally scrolling container using `DistributionalHStackLayout`.
///
/// Scrolling is enabled only when the ideal content width exceeds the
/// available viewport width. The scroll indicator is hidden by default.
public struct DistributionalScrollView<Content: View>: View {
    private let spacing: CGFloat
    private let horizontalInset: CGFloat
    private let contentInsets: EdgeInsets
    private let showsIndicators: Bool
    private let content: () -> Content

    @State private var intrinsicWidth: CGFloat = 0

    public init(
        spacing: CGFloat = 10,
        horizontalInset: CGFloat = 20,
        contentInsets: EdgeInsets = EdgeInsets(),
        showsIndicators: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = max(0, spacing)
        self.horizontalInset = max(0, horizontalInset)
        self.contentInsets = contentInsets
        self.showsIndicators = showsIndicators
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let viewportWidth = max(
                0,
                proxy.size.width
                    - contentInsets.leading
                    - contentInsets.trailing
            )
            let viewportHeight = max(
                0,
                proxy.size.height
                    - contentInsets.top
                    - contentInsets.bottom
            )

            ScrollView(.horizontal) {
                DistributionalHStackLayout(
                    viewportWidth: viewportWidth,
                    spacing: spacing,
                    horizontalInset: horizontalInset
                ) {
                    content()
                }
                .frame(minHeight: viewportHeight)
                .padding(contentInsets)
            }
            .scrollDisabled(intrinsicWidth <= viewportWidth)
            .scrollIndicators(showsIndicators ? .visible : .hidden)
            .overlay(alignment: .topLeading) {
                IntrinsicWidthLayout(
                    spacing: spacing,
                    horizontalInset: horizontalInset
                ) {
                    content()
                }
                .fixedSize(horizontal: true, vertical: false)
                .opacity(0)
                .allowsHitTesting(false)
                .background {
                    GeometryReader { measurement in
                        Color.clear.preference(
                            key: IntrinsicWidthPreferenceKey.self,
                            value: measurement.size.width
                        )
                    }
                }
            }
        }
        .onPreferenceChange(IntrinsicWidthPreferenceKey.self) {
            intrinsicWidth = $0
        }
    }
}

private struct IntrinsicWidthLayout: Layout {
    let spacing: CGFloat
    let horizontalInset: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = sizes.reduce(0) { $0 + $1.width }
            + spacing * CGFloat(max(0, sizes.count - 1))
            + horizontalInset * 2
        let height = sizes.map(\.height).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX + horizontalInset

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width
            if index < subviews.count - 1 {
                x += spacing
            }
        }
    }
}

private struct IntrinsicWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
