import UIKit
import os

public final class CollectionViewDistributionalLayout: CollectionViewLayout {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    var distribution: Distribution? = nil
    let layoutAttributesStorage = LayoutAttributesStorage()
    
    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        
        switch distribution {
        case .none where layoutAttributesStorage.isEmpty:
            // 1. Set estimated
            for (zIndex, indexPath) in collectionView.indexPathSequence.enumerated() {
                layoutAttributesStorage.setEstimatedAttributes(
                    at: indexPath,
                    zIndex: zIndex,
                    of: collectionView
                )
            }
        case .fill:
            // 7. If already all items are self-sized, adjust the layout
            let preferredDistribution = layoutAttributesStorage.preferredDistribution(
                of: collectionView
            )
            switch preferredDistribution {
            case .fill:
                logger.debug("Distribution is fill")
                layoutAttributesStorage.adjustLayoutAttributes { indexPath, x in
                    layoutAttributesStorage.layoutAttributes[indexPath]!.x = x
                    let width = layoutAttributesStorage.layoutAttributes[indexPath]!.width
                    return width
                }
                distribution = .fill
            case .fillEqually:
                logger.debug("Distribution is fillEqually")
                let equalItemWidth = layoutAttributesStorage.equalItemWidth(of: collectionView)
                layoutAttributesStorage.adjustLayoutAttributes { indexPath, x in
                    layoutAttributesStorage.layoutAttributes[indexPath]?.distribution = .fillEqually
                    layoutAttributesStorage.layoutAttributes[indexPath]?.width = equalItemWidth
                    layoutAttributesStorage.layoutAttributes[indexPath]?.x = x
                    return equalItemWidth
                }
                distribution = .fillEqually
            case .fillProportionally:
                logger.debug("Distribution is fillProportionally")
                let proportionalItemSizes = layoutAttributesStorage.proportionalItemSizes(of: collectionView)
                layoutAttributesStorage.adjustLayoutAttributes { indexPath, x in
                    let proportionallyItemWidth = proportionalItemSizes[indexPath]!
                    layoutAttributesStorage.layoutAttributes[indexPath]?.distribution = .fillProportionally
                    layoutAttributesStorage.layoutAttributes[indexPath]?.width = proportionallyItemWidth
                    layoutAttributesStorage.layoutAttributes[indexPath]?.x = x
                    return proportionallyItemWidth
                }
                distribution = .fillProportionally
            }
        default:
            break
        }
        
        collectionViewContentSize.width = layoutAttributesStorage.contentSize().width
        collectionViewContentSize.height = collectionView.safeAreaFrame.height
    }
    
    public override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return nil }
        // 2. Return intersected and estimated items.
        let elements: [UICollectionViewLayoutAttributes] = collectionView.indexPathSequence.compactMap { (indexPath) in
            let layoutAttribute = layoutAttributesStorage.makeUICollectionViewLayoutAttributes(
                forCellWith: indexPath
            )
            // 3. estimated items always intersects
            let intersects = rect.intersects(layoutAttribute.frame)
            guard intersects else {
                return nil
            }
            return layoutAttribute
        }
        return elements
    }
    
    public override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        layoutAttributesStorage.makeUICollectionViewLayoutAttributes(
            forCellWith: indexPath
        )
    }
    
    public override func shouldInvalidateLayout(
        forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
        withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
    ) -> Bool {
        let layoutAttribute = layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath]!
        switch layoutAttribute.distribution {
        case .none, .fill:
            // 4. If the item is not self-sized, invalidate the layout
            return originalAttributes.size.width != preferredAttributes.size.width
        case .fillEqually, .fillProportionally:
            // 8. All items are self-sized, no need to invalidate the layout
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
        
        let isAboveLeftEdge = preferredAttributes.frame.minX < (collectionView?.bounds.minX ?? 0)
        context.contentOffsetAdjustment.x -= isAboveLeftEdge ? -widthDiff : 0
        
        // 5. Update the self-sized attributes
        layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath] = LayoutAttributes(
            distribution: .fill,
            x: preferredAttributes.frame.minX,
            width: preferredAttributes.size.width,
            height: collectionView!.safeAreaFrame.height,
            zIndex: preferredAttributes.zIndex
        )
        
        return context
    }
    
    public override func invalidateLayout(
        with context: UICollectionViewLayoutInvalidationContext
    ) {
        super.invalidateLayout(with: context)
        
        // 6. After self-sized items are invalidated, update the distribution flag
        if !layoutAttributesStorage.layoutAttributes.isEmpty && layoutAttributesStorage.layoutAttributes.allSatisfy({ $0.value.distribution == .fill }) {
            distribution = .fill
        }
        
        // 0. if the data source is invalidated, reset the layout
        if context.invalidateDataSourceCounts {
            layoutAttributesStorage.layoutAttributes.removeAll()
            distribution = nil
        }
    }
}

