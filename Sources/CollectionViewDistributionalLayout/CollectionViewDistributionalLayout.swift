import UIKit
import os

public final class CollectionViewDistributionalLayout: CollectionViewLayout {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    let layoutAttributesStorage = LayoutAttributesStorage()
    lazy var currentBounds: CGRect = collectionView?.bounds ?? .zero
    
    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        
        for (zIndex, indexPath) in collectionView.indexPathSequence.enumerated() {
            if layoutAttributesStorage.layoutAttributes[indexPath] == nil {
                layoutAttributesStorage.setEstimatedAttributes(
                    at: indexPath,
                    zIndex: zIndex,
                    of: collectionView
                )
            }
        }
        
        // 7. If already all items are self-sized, adjust the layout
        let preferredDistribution = layoutAttributesStorage.preferredDistribution(
            of: collectionView
        )
        switch preferredDistribution {
        case .fill:
            logger.debug("Distribution is fill")
            layoutAttributesStorage.adjustLayoutAttributes { indexPath, xPosition in
                layoutAttributesStorage.layoutAttributes[indexPath]!.frame.origin.x = xPosition
                layoutAttributesStorage.layoutAttributes[indexPath]!.frame.size.width =
                layoutAttributesStorage.layoutAttributes[indexPath]!.intrinsicFrame.size.width
                let itemWidth = layoutAttributesStorage.layoutAttributes[indexPath]!.frame.size.width
                return itemWidth
            }
        case .fillEqually:
            logger.debug("Distribution is fillEqually")
            let equalItemWidth = layoutAttributesStorage.equalItemWidth(of: collectionView)
            layoutAttributesStorage.adjustLayoutAttributes { indexPath, xPosition in
                layoutAttributesStorage.layoutAttributes[indexPath]?.frame.size.width = equalItemWidth
                layoutAttributesStorage.layoutAttributes[indexPath]?.frame.origin.x = xPosition
                return equalItemWidth
            }
        case .fillProportionally:
            logger.debug("Distribution is fillProportionally")
            let proportionalItemSizes = layoutAttributesStorage.proportionalItemSizes(of: collectionView)
            layoutAttributesStorage.adjustLayoutAttributes { indexPath, xPosition in
                let proportionalItemWidth = proportionalItemSizes[indexPath]!
                layoutAttributesStorage.layoutAttributes[indexPath]?.frame.size.width = proportionalItemWidth
                layoutAttributesStorage.layoutAttributes[indexPath]?.frame.origin.x = xPosition
                return proportionalItemWidth
            }
        }
        
        collectionViewContentSize.width = layoutAttributesStorage.contentSize(preferredSize: false).width
        collectionViewContentSize.height = collectionView.safeAreaFrame.height
    }
    
    public override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return nil }
        // 2. Return intersected and estimated items.
        let visibleElements: [UICollectionViewLayoutAttributes] = collectionView.indexPathSequence.compactMap { (indexPath) in
            guard let layoutAttributes = layoutAttributesStorage.makeUICollectionViewLayoutAttributes(
                forCellWith: indexPath
            ) else {
                return nil
            }
            // 3. estimated items always intersects
            let isIntersecting = rect.intersects(layoutAttributes.frame)
            guard isIntersecting else {
                return nil
            }
            return layoutAttributes
        }
        let availableIndexPaths = collectionView.indexPathSequence.map({ $0 })
        return visibleElements.filter({ availableIndexPaths.contains($0.indexPath) })
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
        guard let currentLayoutAttributes = layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath] else {
            return true // If layout attributes don't exist yet, invalidate to create them
        }
        return currentLayoutAttributes.preferredFrame == nil
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
        guard layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath] != nil else {
            return context
        }
        layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath]!.preferredFrame = preferredAttributes.frame
        layoutAttributesStorage.invalidateCachePublic()
        
        return context
    }
    
    public override func invalidateLayout(
        with context: UICollectionViewLayoutInvalidationContext
    ) {
        super.invalidateLayout(with: context)
        // 0. if the data source is invalidated, reset the layout
        if context.invalidateDataSourceCounts {
            layoutAttributesStorage.layoutAttributes.removeAll()
        }
    }
    
    // Ex: Orientation
    public override func didChangedCollectionViewSize(_ newSize: CGSize) {
        super.didChangedCollectionViewSize(newSize)
        layoutAttributesStorage.layoutAttributes.removeAll()
    }
    
    // Ex: Split View
    public override func shouldInvalidateLayout(
        forBoundsChange newBounds: CGRect
    ) -> Bool {
        currentBounds != newBounds
    }
    
    public override func invalidationContext(
        forBoundsChange newBounds: CGRect
    ) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        if currentBounds.width != newBounds.width {
            layoutAttributesStorage.layoutAttributes.removeAll()
            currentBounds = newBounds
        }
        
        return context
    }
}

