import UIKit
import os
import OrderedCollections

public final class CollectionViewDistributionalLayout: CollectionViewLayout {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    var distribution: Distribution? = nil
    var layoutAttributes: OrderedDictionary<IndexPath, LayoutAttributes> = [:]
    let estimatedItemSize = CGSize(width: 200, height: 200)
    
    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        
        switch distribution {
        case .none where layoutAttributes.isEmpty:
            for (zIndex, indexPath) in collectionView.indexPathSequence.enumerated() {
                let width = estimatedItemSize.width
                layoutAttributes[indexPath] = LayoutAttributes(
                    distribution: nil,
                    x: 0, // shouldInvalidateを呼ばせるために、見える位置に配置する
                    width: width,
                    zIndex: zIndex
                )
            }
        case .fill:
            let reducedWidth = layoutAttributes.values.map(\.width).reduce(0, +)
            
            if reducedWidth <= collectionView.safeAreaFrame.width {
                let maxItemWidth = layoutAttributes.values.map(\.width).max() ?? 0
                let equalItemWidth = collectionView.safeAreaFrame.width / CGFloat(layoutAttributes.count)
                if maxItemWidth <= equalItemWidth {
                    logger.debug("Distribution is fillEqually")
                    var offsetX: CGFloat = 0
                    for indexPath in layoutAttributes.keys {
                        layoutAttributes[indexPath]?.distribution = .fillEqually
                        layoutAttributes[indexPath]?.width = equalItemWidth
                        layoutAttributes[indexPath]?.x = offsetX
                        offsetX += equalItemWidth
                    }
                    distribution = .fillEqually
                } else {
                    logger.debug("Distribution is fillProportionally")
                    var offsetX: CGFloat = 0
                    for indexPath in layoutAttributes.keys {
                        let baseWidth = layoutAttributes[indexPath]!.width
                        let proportionallyItemWidth = baseWidth / reducedWidth * collectionView.safeAreaFrame.width
                        layoutAttributes[indexPath]?.distribution = .fillProportionally
                        layoutAttributes[indexPath]?.width = proportionallyItemWidth
                        layoutAttributes[indexPath]?.x = offsetX
                        offsetX += proportionallyItemWidth
                    }
                    distribution = .fillProportionally
                }
            } else {
                logger.debug("Distribution is fill")
                var offset: CGFloat = 0
                for key in layoutAttributes.keys {
                    layoutAttributes[key]!.x = offset
                    offset += layoutAttributes[key]!.width
                }
                distribution = .fill
            }
        default:
            break
        }
        
        collectionViewContentSize.width = layoutAttributes.values.map(\.width).reduce(0, +)
        collectionViewContentSize.height = collectionView.safeAreaFrame.height
    }
    
    public override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return nil }
        let elements: [UICollectionViewLayoutAttributes] = collectionView.indexPathSequence.compactMap { (indexPath) in
            let layoutAttribute = makeUICollectionViewLayoutAttributes(forCellWith: indexPath)
            let isAutomaticSize = layoutAttribute.frame.width == estimatedItemSize.width
            let intersects = rect.intersects(layoutAttribute.frame)
            guard intersects || isAutomaticSize else {
                return nil
            }
            return layoutAttribute
        }
        logger.debug("layoutAttributesForElements \(elements.count)")
        return elements
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        logger.debug("layoutAttributesForItem at \(indexPath)")
        return makeUICollectionViewLayoutAttributes(forCellWith: indexPath)
    }
    
    func makeUICollectionViewLayoutAttributes(forCellWith indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = layoutAttributes[indexPath]!
        let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.frame = CGRect(
            x: layoutAttributes.x,
            y: 0,
            width: layoutAttributes.width,
            height: collectionViewContentSize.height
        )
        attrs.zIndex = layoutAttributes.zIndex
        return attrs
    }
    
    public override func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> Bool {
        // ここが全てのindexPath分呼ばれないことがある
        let layoutAttribute = layoutAttributes[preferredAttributes.indexPath]!
        switch layoutAttribute.distribution {
        case .none, .fill:
            return originalAttributes.size.width != preferredAttributes.size.width
        case .fillEqually, .fillProportionally:
            return false
        }
    }
    
    public override func invalidationContext(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(
            forPreferredLayoutAttributes: preferredAttributes,
            withOriginalAttributes: originalAttributes
        )
        
        let widthDiff = originalAttributes.frame.width - preferredAttributes.frame.width
        context.contentSizeAdjustment.width -= widthDiff
        
        let isAboveTopEdge = preferredAttributes.frame.minX < (collectionView?.bounds.minX ?? 0)
        context.contentOffsetAdjustment.x -= isAboveTopEdge ? -widthDiff : 0
        
        layoutAttributes[preferredAttributes.indexPath] = LayoutAttributes(
            distribution: .fill,
            x: preferredAttributes.frame.minX,
            width: preferredAttributes.size.width,
            zIndex: preferredAttributes.zIndex
        )
        
        return context
    }
    
    public override func invalidateLayout(
        with context: UICollectionViewLayoutInvalidationContext
    ) {
        super.invalidateLayout(with: context)
        
        if !layoutAttributes.isEmpty && layoutAttributes.allSatisfy({ $0.value.distribution == .fill }) {
            distribution = .fill
        }
        
        if context.invalidateDataSourceCounts {
            layoutAttributes.removeAll()
            distribution = nil
        }
    }
}

