import OrderedCollections
import UIKit
import Algorithms
import os

final class LayoutAttributesStorage {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    var layoutAttributes: OrderedDictionary<IndexPath, LayoutAttributes> = [:] {
        didSet {
            cache.invalidateAll()
        }
    }
    let estimatedItemSize = CGSize(width: 200, height: 200)
    var sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    var minimumInteritemSpacing: CGFloat = 10
    
    // Performance cache
    private let cache = LayoutCache()
    
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
    
    func invalidateCachePublic() {
        cache.invalidateAll()
    }
    
    @MainActor
    func makeUICollectionViewLayoutAttributes(
        forCellWith indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = layoutAttributes[indexPath]!
        let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.frame = layoutAttributes.frame
        attrs.zIndex = layoutAttributes.zIndex
        return attrs
    }
    
    func contentSize(preferredSize: Bool) -> CGSize {
        return cache.contentSize(preferredSize: preferredSize) {
            var size: CGSize = .zero
            for section in sectionSequence() {
                let sectionSize = self.sectionSize(at: section, preferredSize: preferredSize)
                size.width += sectionSize.width
                size.height = max(sectionSize.height, size.height)
            }
            return size
        }
    }
    
    func sectionSize(at section: Int, preferredSize: Bool) -> CGSize {
        return cache.sectionSize(for: section, preferredSize: preferredSize) {
            var size: CGSize = .zero
            size.width += sectionInset.left
            let rows = rowSequence(in: section)
            for row in rows {
                let indexPath = IndexPath(row: row, section: section)
                let layoutAttributes = layoutAttributes[indexPath]!
                size.width += preferredSize ? layoutAttributes.intrinsicFrame.width : layoutAttributes.frame.width
                size.width += minimumInteritemSpacing
                size.height = max(layoutAttributes.frame.height, size.height)
            }
            if rows.count >= 1 {
                size.width -= minimumInteritemSpacing
            }
            size.width += sectionInset.right
            return size
        }
    }
    
    func allItemWidth(at section: Int) -> CGFloat {
        return cache.allItemWidth(for: section) {
            var total: CGFloat = 0
            for (indexPath, attributes) in layoutAttributes {
                if indexPath.section == section {
                    total += attributes.intrinsicFrame.width
                }
            }
            return total
        }
    }
    
    func maxItemWidth() -> CGFloat {
        return cache.maxItemWidth {
            layoutAttributes.values.map(\.intrinsicFrame.width).max() ?? 0
        }
    }
    
    @MainActor
    func equalItemWidth(of collectionView: UICollectionView) -> CGFloat {
        return cache.equalItemWidth {
            var width = collectionView.safeAreaFrame.width
            for section in sectionSequence() {
                width -= sectionInset.left
                let rows = rowSequence(in: section)
                let spacings = rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
                width -= spacings
                width -= sectionInset.right
            }
            width /= layoutAttributes.count > 0 ? CGFloat(layoutAttributes.count) : 1
            return width
        }
    }
    
    @MainActor
    func proportionalItemSizes(
        of collectionView: UICollectionView
    ) -> [IndexPath : CGFloat] {
        return cache.proportionalItemSizes {
            var sizes: [IndexPath : CGFloat] = [:]
            let proportionalSectionSizes = proportionalSectionSizes(of: collectionView)
            for section in sectionSequence() {
                let sectionWidth = proportionalSectionSizes[section]!
                let sectionItemWidth = allItemWidth(at: section)
                let rows = rowSequence(in: section)
                
                let sectionInsets = sectionInset.left + sectionInset.right
                let spacings = rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
                let availableItemWidth = sectionWidth - sectionInsets - spacings
                
                for row in rows {
                    let indexPath = IndexPath(row: row, section: section)
                    let layoutAttributes = layoutAttributes[indexPath]!
                    let proportionalRatio = sectionItemWidth > 0 ? layoutAttributes.intrinsicFrame.width / sectionItemWidth : 0
                    let proportionallyItemWidth = proportionalRatio * availableItemWidth
                    sizes[indexPath] = proportionallyItemWidth
                }
            }
            return sizes
        }
    }
    
    @MainActor
    func proportionalSectionSizes(
        of collectionView: UICollectionView
    ) -> [Int : CGFloat] {
        var sizes: [Int : CGFloat] = [:]
        let sections = sectionSequence()
        
        // Calculate all section widths in one pass
        var allSectionWidth: CGFloat = 0
        var sectionWidths: [Int: CGFloat] = [:]
        
        for section in sections {
            let width = sectionSize(at: section, preferredSize: true).width
            sectionWidths[section] = width
            allSectionWidth += width
        }
        
        guard allSectionWidth > 0 else {
            return sections.reduce(into: [:]) { $0[$1] = 0 }
        }
        
        let availableContentWidth = collectionView.safeAreaFrame.width
        for section in sections {
            let sectionWidth = sectionWidths[section]!
            let proportionalRatio = sectionWidth / allSectionWidth
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
    
    func adjustLayoutAttributes(_ update: (_ indexPath: IndexPath, _ x: CGFloat) -> CGFloat) {
        var offsetX: CGFloat = .zero
        for section in sectionSequence() {
            offsetX += sectionInset.left
            let rows = rowSequence(in: section)
            for row in rows {
                let indexPath = IndexPath(row: row, section: section)
                offsetX += update(indexPath, offsetX)
                offsetX += minimumInteritemSpacing
            }
            if rows.count >= 1 {
                offsetX -= minimumInteritemSpacing
            }
            offsetX += sectionInset.right
        }
        // Layout attributes were modified, invalidate cache
        cache.invalidateAll()
    }
    
    func sectionSequence() -> [Int] {
        return cache.sectionSequence {
            Array(Set(layoutAttributes.keys.map(\.section))).sorted()
        }
    }
    
    func rowSequence(in section: Int) -> [Int] {
        return cache.rowSequence(for: section) {
            Array(Set(layoutAttributes.keys.filter({ $0.section == section }).map(\.row))).sorted()
        }
    }
}
