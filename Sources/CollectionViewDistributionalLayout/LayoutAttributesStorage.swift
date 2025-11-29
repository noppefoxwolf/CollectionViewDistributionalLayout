import UIKit
import os

final class LayoutAttributesStorage {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
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
                height: collectionView.safeAreaFrame.inset(by: sectionInset).height
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
        for section in sectionSequence() {
            let sectionSize = self.sectionSize(at: section, preferredSize: preferredSize)
            size.width += sectionSize.width
            size.height = max(sectionSize.height, size.height)
        }
        return size
    }
    
    func sectionSize(at section: Int, preferredSize: Bool) -> CGSize {
        var size: CGSize = .zero
        size.width += sectionInset.left
        let rows = rowSequence(in: section)
        for row in rows {
            let indexPath = IndexPath(row: row, section: section)
            let currentLayoutAttributes = layoutAttributes[indexPath]!
            size.width += preferredSize ? currentLayoutAttributes.intrinsicFrame.width : currentLayoutAttributes.frame.width
            size.width += minimumInteritemSpacing
            size.height = max(currentLayoutAttributes.frame.height, size.height)
        }
        if rows.count >= 1 {
            size.width -= minimumInteritemSpacing
        }
        size.width += sectionInset.right
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
        var availableWidth = collectionView.safeAreaFrame.width
        var totalSpacing: CGFloat = 0
        
        for section in sectionSequence() {
            let rows = rowSequence(in: section)
            totalSpacing += rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
        }
        
        // セクションのインセットは全体で一度だけ適用
        availableWidth -= sectionInset.left + sectionInset.right
        availableWidth -= totalSpacing
        
        let totalItemCount = layoutAttributes.count > 0 ? CGFloat(layoutAttributes.count) : 1
        availableWidth /= totalItemCount
        return availableWidth
    }
    
    @MainActor
    func proportionalItemSizes(
        of collectionView: UICollectionView
    ) -> [IndexPath : CGFloat] {
        var sizes: [IndexPath : CGFloat] = [:]
        let proportionalSectionSizes = proportionalSectionSizes(of: collectionView)
        for section in sectionSequence() {
            let sectionWidth = proportionalSectionSizes[section]!
            let sectionItemWidth = allItemWidth(at: section)
            let rows = rowSequence(in: section)
            
            let sectionInsets = sectionInset.left + sectionInset.right
            let totalSpacing = rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
            let availableItemWidth = sectionWidth - sectionInsets - totalSpacing
            
            for row in rows {
                let indexPath = IndexPath(row: row, section: section)
                let itemLayoutAttributes = layoutAttributes[indexPath]!
                let proportionalRatio = sectionItemWidth > 0 ? itemLayoutAttributes.intrinsicFrame.width / sectionItemWidth : 0
                let proportionalItemWidth = proportionalRatio * availableItemWidth
                sizes[indexPath] = proportionalItemWidth
            }
        }
        return sizes
    }
    
    @MainActor
    func proportionalSectionSizes(
        of collectionView: UICollectionView
    ) -> [Int : CGFloat] {
        var sizes: [Int : CGFloat] = [:]
        let sections = sectionSequence()
        
        // Calculate all section widths in one pass
        var totalSectionWidth: CGFloat = 0
        var individualSectionWidths: [Int: CGFloat] = [:]
        
        for section in sections {
            let sectionWidth = sectionSize(at: section, preferredSize: true).width
            individualSectionWidths[section] = sectionWidth
            totalSectionWidth += sectionWidth
        }
        
        guard totalSectionWidth > 0 else {
            return sections.reduce(into: [:]) { $0[$1] = 0 }
        }
        
        let availableContentWidth = collectionView.safeAreaFrame.width
        for section in sections {
            let sectionWidth = individualSectionWidths[section]!
            let proportionalRatio = sectionWidth / totalSectionWidth
            sizes[section] = proportionalRatio * availableContentWidth
        }
        return sizes
    }
    
    @MainActor
    func preferredDistribution(of collectionView: UICollectionView) -> Distribution {
        let contentWidth = contentSize(preferredSize: true).width
        if contentWidth <= collectionView.safeAreaFrame.width {
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
    func adjustLayoutAttributes(collectionView: UICollectionView, respectSafeArea: Bool = true, _ updateCallback: (_ indexPath: IndexPath, _ xPosition: CGFloat) -> CGFloat) {
        let startX: CGFloat = respectSafeArea ? collectionView.safeAreaInsets.left + sectionInset.left : sectionInset.left
        var currentX: CGFloat = startX
        
        for section in sectionSequence() {
            let rows = rowSequence(in: section)
            for row in rows {
                let indexPath = IndexPath(row: row, section: section)
                currentX += updateCallback(indexPath, currentX)
                currentX += minimumInteritemSpacing
            }
            if rows.count >= 1 {
                currentX -= minimumInteritemSpacing
            }
        }
    }
    
    func sectionSequence() -> [Int] {
        return Array(Set(layoutAttributes.keys.map(\.section))).sorted()
    }
    
    func rowSequence(in section: Int) -> [Int] {
        return Array(Set(layoutAttributes.keys.filter({ $0.section == section }).map(\.row))).sorted()
    }
}
