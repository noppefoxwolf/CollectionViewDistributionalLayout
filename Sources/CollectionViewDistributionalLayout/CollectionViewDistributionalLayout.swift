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
            for (zIndex, indexPath) in collectionView.indexPathSequence.enumerated() {
                layoutAttributesStorage.setEstimatedAttributes(at: indexPath, zIndex: zIndex)
            }
        case .fill:
            let contentWidth = layoutAttributesStorage.contentWidth()
            
            if contentWidth <= collectionView.safeAreaFrame.width {
                let maxItemWidth = layoutAttributesStorage.maxItemWidth()
                let equalItemWidth = layoutAttributesStorage.equalItemWidth(of: collectionView)
                if maxItemWidth <= equalItemWidth {
                    logger.debug("Distribution is fillEqually")
                    var offsetX: CGFloat = layoutAttributesStorage.sectionInset.left
                    // TODO: ２個以上のセクションに対応する
                    for indexPath in layoutAttributesStorage.layoutAttributes.keys {
                        layoutAttributesStorage.layoutAttributes[indexPath]?.distribution = .fillEqually
                        layoutAttributesStorage.layoutAttributes[indexPath]?.width = equalItemWidth
                        layoutAttributesStorage.layoutAttributes[indexPath]?.x = offsetX
                        offsetX += equalItemWidth
                    }
                    offsetX += layoutAttributesStorage.sectionInset.right
                    distribution = .fillEqually
                } else {
                    logger.debug("Distribution is fillProportionally")
                    var offsetX: CGFloat = layoutAttributesStorage.sectionInset.left
                    // TODO: ２個以上のセクションに対応する
                    let proportionalItemSizes = layoutAttributesStorage.proportionalItemSizes(of: collectionView)
                    for indexPath in layoutAttributesStorage.layoutAttributes.keys {
                        let proportionallyItemWidth = proportionalItemSizes[indexPath]!
                        layoutAttributesStorage.layoutAttributes[indexPath]?.distribution = .fillProportionally
                        layoutAttributesStorage.layoutAttributes[indexPath]?.width = proportionallyItemWidth
                        layoutAttributesStorage.layoutAttributes[indexPath]?.x = offsetX
                        offsetX += proportionallyItemWidth
                    }
                    offsetX += layoutAttributesStorage.sectionInset.right
                    distribution = .fillProportionally
                }
            } else {
                logger.debug("Distribution is fill")
                var offsetX: CGFloat = layoutAttributesStorage.sectionInset.left
                for key in layoutAttributesStorage.layoutAttributes.keys {
                    layoutAttributesStorage.layoutAttributes[key]!.x = offsetX
                    offsetX += layoutAttributesStorage.layoutAttributes[key]!.width
                }
                offsetX += layoutAttributesStorage.sectionInset.right
                distribution = .fill
            }
        default:
            break
        }
        
        collectionViewContentSize.width = layoutAttributesStorage.contentWidth()
        collectionViewContentSize.height = collectionView.safeAreaFrame.height
    }
    
    public override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return nil }
        let elements: [UICollectionViewLayoutAttributes] = collectionView.indexPathSequence.compactMap { (indexPath) in
            let layoutAttribute = makeUICollectionViewLayoutAttributes(forCellWith: indexPath)
            let isAutomaticSize = layoutAttribute.frame.width == layoutAttributesStorage.estimatedItemSize.width
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
        let layoutAttributes = layoutAttributesStorage.layoutAttributes[indexPath]!
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
        let layoutAttribute = layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath]!
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
        
        layoutAttributesStorage.layoutAttributes[preferredAttributes.indexPath] = LayoutAttributes(
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
        
        if !layoutAttributesStorage.layoutAttributes.isEmpty && layoutAttributesStorage.layoutAttributes.allSatisfy({ $0.value.distribution == .fill }) {
            distribution = .fill
        }
        
        if context.invalidateDataSourceCounts {
            layoutAttributesStorage.layoutAttributes.removeAll()
            distribution = nil
        }
    }
}

