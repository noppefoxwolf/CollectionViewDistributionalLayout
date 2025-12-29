import UIKit
import os

final class LayoutAttributesStorage {
    var layoutAttributes: [IndexPath: LayoutAttributes] = [:]
    let estimatedItemSize = CGSize(width: 200, height: 200)
    var sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    var minimumInteritemSpacing: CGFloat = 10
    
    var isEmpty: Bool { layoutAttributes.isEmpty }
    
    @MainActor
    func setEstimatedAttributes(
        at indexPath: IndexPath,
        zIndex: Int,
        of collectionView: UICollectionView        
    ) {
        layoutAttributes[indexPath] = LayoutAttributes(
            frame: CGRect(
                x: sectionInset.left, // shouldInvalidateを呼ばせるために、見える位置に配置する
                y: 0,
                width: estimatedItemSize.width,
                height: collectionView.adjustedContentFrame.inset(by: sectionInset).height
            ),
            zIndex: zIndex
        )
    }

    
    @MainActor
    func makeUICollectionViewLayoutAttributes(
        forCellWith indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributesData = layoutAttributes[indexPath] else {
            return nil
        }
        let uiAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        uiAttributes.frame = layoutAttributesData.frame
        uiAttributes.zIndex = layoutAttributesData.zIndex
        return uiAttributes
    }
    
    func contentSize(preferredSize: Bool) -> CGSize {
        var size: CGSize = .zero
        let indexPaths = orderedIndexPaths()
        guard !indexPaths.isEmpty else {
            return size
        }
        
        size.width += sectionInset.left
        for (index, indexPath) in indexPaths.enumerated() {
            let currentLayoutAttributes = layoutAttributes[indexPath]!
            size.width += preferredSize ? currentLayoutAttributes.intrinsicFrame.width : currentLayoutAttributes.frame.width
            if index < indexPaths.count - 1 {
                size.width += minimumInteritemSpacing
            }
            size.height = max(currentLayoutAttributes.frame.height, size.height)
        }
        size.width += sectionInset.right
        return size
    }
    
    func sectionSize(at section: Int, preferredSize: Bool) -> CGSize {
        var size: CGSize = .zero
        let rows = rowSequence(in: section)
        for (index, row) in rows.enumerated() {
            let indexPath = IndexPath(row: row, section: section)
            let currentLayoutAttributes = layoutAttributes[indexPath]!
            size.width += preferredSize ? currentLayoutAttributes.intrinsicFrame.width : currentLayoutAttributes.frame.width
            if index < rows.count - 1 {
                size.width += minimumInteritemSpacing
            }
            size.height = max(currentLayoutAttributes.frame.height, size.height)
        }
        return size
    }
    
    func allItemWidth(at section: Int) -> CGFloat {
        var totalWidth: CGFloat = 0
        for (indexPath, layoutAttributesData) in layoutAttributes {
            if indexPath.section == section {
                totalWidth += layoutAttributesData.intrinsicFrame.width
            }
        }
        return totalWidth
    }
    
    func maxItemWidth() -> CGFloat {
        return layoutAttributes.values.map(\.intrinsicFrame.width).max() ?? 0
    }
    
    @MainActor
    func equalItemWidth(of collectionView: UICollectionView) -> CGFloat {
        var availableWidth = collectionView.adjustedContentFrame.width
        let totalItemCount = layoutAttributes.count
        let totalSpacing = totalItemCount > 1 ? minimumInteritemSpacing * CGFloat(totalItemCount - 1) : 0
        
        // セクションのインセットは全体で一度だけ適用
        availableWidth -= sectionInset.left + sectionInset.right
        availableWidth -= totalSpacing
        
        let totalItemCountSafe = totalItemCount > 0 ? CGFloat(totalItemCount) : 1
        availableWidth /= totalItemCountSafe
        return availableWidth
    }
    
    @MainActor
    func proportionalItemSizes(
        of collectionView: UICollectionView
    ) -> [IndexPath : CGFloat] {
        var sizes: [IndexPath : CGFloat] = [:]
        let totalItemWidth = layoutAttributes.values.reduce(0) { $0 + $1.intrinsicFrame.width }
        let totalItemCount = layoutAttributes.count
        let totalSpacing = totalItemCount > 1 ? minimumInteritemSpacing * CGFloat(totalItemCount - 1) : 0
        let availableItemWidth = collectionView.adjustedContentFrame.width
            - sectionInset.left
            - sectionInset.right
            - totalSpacing
        
        for (indexPath, itemLayoutAttributes) in layoutAttributes {
            let proportionalRatio = totalItemWidth > 0 ? itemLayoutAttributes.intrinsicFrame.width / totalItemWidth : 0
            sizes[indexPath] = proportionalRatio * availableItemWidth
        }
        return sizes
    }
    
    @MainActor
    func preferredDistribution(of collectionView: UICollectionView) -> Distribution {
        let contentWidth = contentSize(preferredSize: true).width
        if contentWidth <= collectionView.adjustedContentFrame.width {
            let maxItemWidth = maxItemWidth()
            let equalItemWidth = equalItemWidth(of: collectionView)
            if maxItemWidth <= equalItemWidth {
                return .fillEqually
            } else {
                return .fillProportionally
            }
        } else {
            return .fill
        }
    }
    
    @MainActor
    func adjustLayoutAttributes(collectionView: UICollectionView, respectAdjustedContentInset: Bool = true, _ updateCallback: (_ indexPath: IndexPath, _ xPosition: CGFloat) -> CGFloat) {
        let startX: CGFloat = sectionInset.left
        var currentX: CGFloat = startX
        let indexPaths = orderedIndexPaths()
        for (index, indexPath) in indexPaths.enumerated() {
            currentX += updateCallback(indexPath, currentX)
            if index < indexPaths.count - 1 {
                currentX += minimumInteritemSpacing
            }
        }
    }
    
    func sectionSequence() -> [Int] {
        return Array(Set(layoutAttributes.keys.map(\.section))).sorted()
    }
    
    func rowSequence(in section: Int) -> [Int] {
        return Array(Set(layoutAttributes.keys.filter({ $0.section == section }).map(\.row))).sorted()
    }
    
    private func orderedIndexPaths() -> [IndexPath] {
        sectionSequence().flatMap { section in
            rowSequence(in: section).map { row in
                IndexPath(row: row, section: section)
            }
        }
    }
}
