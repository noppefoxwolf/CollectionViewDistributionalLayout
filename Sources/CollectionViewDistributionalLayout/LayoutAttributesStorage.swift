import OrderedCollections
import UIKit
import Algorithms
import os

final class LayoutAttributesStorage {
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    var layoutAttributes: OrderedDictionary<IndexPath, LayoutAttributes> = [:]
    let estimatedItemSize = CGSize(width: 200, height: 200)
    var sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    var minimumInteritemSpacing: CGFloat = 10
    
    var isEmpty: Bool { layoutAttributes.isEmpty }
    
    func setEstimatedAttributes(at indexPath: IndexPath, zIndex: Int) {
        layoutAttributes[indexPath] = LayoutAttributes(
            distribution: nil,
            x: sectionInset.left, // shouldInvalidateを呼ばせるために、見える位置に配置する
            width: estimatedItemSize.width,
            height: estimatedItemSize.height,
            zIndex: zIndex
        )
    }
    
    @MainActor
    func makeUICollectionViewLayoutAttributes(
        forCellWith indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = layoutAttributes[indexPath]!
        let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.frame = CGRect(
            x: layoutAttributes.x,
            y: 0,
            width: layoutAttributes.width,
            height: layoutAttributes.height
        )
        attrs.zIndex = layoutAttributes.zIndex
        return attrs
    }
    
    func contentSize() -> CGSize {
        // FIXME: height is not supported
        var size: CGSize = .zero
        for section in sectionSequence() {
            let sectionSize = sectionSize(at: section)
            size.width += sectionSize.width
        }
        return size
    }
    
    func sectionSize(at section: Int) -> CGSize {
        // FIXME: height is not supported
        var size: CGSize = .zero
        size.width += sectionInset.left
        let rows = rowSequence(in: section)
        for row in rows {
            let indexPath = IndexPath(row: row, section: section)
            let layoutAttributes = layoutAttributes[indexPath]!
            size.width += layoutAttributes.width
            size.width += minimumInteritemSpacing
        }
        if rows.count >= 1 {
            size.width -= minimumInteritemSpacing
        }
        size.width += sectionInset.right
        return size
    }
    
    func itemWidth(at section: Int) -> CGFloat {
        layoutAttributes.filter({ $0.key.section == section }).values.map(\.width).reduce(0, +)
    }
    
    func maxItemWidth() -> CGFloat {
        layoutAttributes.values.map(\.width).max() ?? 0
    }
    
    @MainActor
    func equalItemWidth(of collectionView: UICollectionView) -> CGFloat {
        var width = collectionView.safeAreaFrame.width
        for section in sectionSequence() {
            width -= sectionInset.left
            let rows = rowSequence(in: section)
            let spacings = rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
            width -= spacings
            width -= sectionInset.right
        }
        width /= CGFloat(layoutAttributes.count)
        return width
    }
    
    @MainActor
    func proportionalItemSizes(
        of collectionView: UICollectionView
    ) -> [IndexPath : CGFloat] {
        var sizes: [IndexPath : CGFloat] = [:]
        let proportionalSectionSizes = proportionalSectionSizes(of: collectionView)
        for section in sectionSequence() {
            let sectionWidth = proportionalSectionSizes[section]!
            let sectionItemWidth = itemWidth(at: section)
            let rows = rowSequence(in: section)
            
            let sectionInsets = sectionInset.left + sectionInset.right
            let spacings = rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
            let availableItemWidth = sectionWidth - sectionInsets - spacings
            
            for row in rows {
                let indexPath = IndexPath(row: row, section: section)
                let layoutAttributes = layoutAttributes[indexPath]!
                let proportionalRatio = layoutAttributes.width / sectionItemWidth
                let proportionallyItemWidth = proportionalRatio * availableItemWidth
                sizes[indexPath] = proportionallyItemWidth
            }
        }
        return sizes
    }
    
    @MainActor
    func proportionalSectionSizes(
        of collectionView: UICollectionView
    ) -> [Int : CGFloat] {
        var sizes: [Int : CGFloat] = [:]
        let allSectionWidth = sectionSequence().map(sectionSize(at:)).map(\.width).reduce(0.0, +)
        for section in sectionSequence() {
            let sectionSize = sectionSize(at: section)
            let proportionalRatio = sectionSize.width / allSectionWidth
            let availableContentWidth = collectionView.safeAreaFrame.width
            let proportionallySectionWidth = proportionalRatio * availableContentWidth
            sizes[section] = proportionallySectionWidth
        }
        return sizes
    }
    
    @MainActor
    func preferredDistribution(of collectionView: UICollectionView) -> Distribution {
        let contentWidth = contentSize().width
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
    }
    
    func sectionSequence() -> [Int] {
        layoutAttributes.keys.map(\.section).uniqued().sorted()
    }
    
    func rowSequence(in section: Int) -> [Int] {
        layoutAttributes.keys.filter({ $0.section == section }).map(\.row).uniqued().sorted()
    }
}
