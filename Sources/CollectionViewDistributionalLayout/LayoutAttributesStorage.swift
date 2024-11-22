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
    
    @MainActor
    func setEstimatedAttributes(
        at indexPath: IndexPath,
        zIndex: Int,
        of collectionView: UICollectionView        
    ) {
        layoutAttributes[indexPath] = LayoutAttributes(
            distribution: nil,
            frame: CGRect(
                x: sectionInset.left, // shouldInvalidateを呼ばせるために、見える位置に配置する
                y: 0,
                width: estimatedItemSize.width,
                height: collectionView.safeAreaFrame.inset(by: sectionInset).height
            ),
            zIndex: zIndex
        )
    }
    
    func unmarkDistributions() {
        for indexPath in layoutAttributes.keys {
            layoutAttributes[indexPath]?.distribution = nil
        }
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
    
    func contentSize() -> CGSize {
        var size: CGSize = .zero
        for section in sectionSequence() {
            let sectionSize = sectionSize(at: section)
            size.width += sectionSize.width
            size.height = max(sectionSize.height, size.height)
        }
        return size
    }
    
    func sectionSize(at section: Int) -> CGSize {
        var size: CGSize = .zero
        size.width += sectionInset.left
        let rows = rowSequence(in: section)
        for row in rows {
            let indexPath = IndexPath(row: row, section: section)
            let layoutAttributes = layoutAttributes[indexPath]!
            size.width += layoutAttributes.frame.width
            size.width += minimumInteritemSpacing
            size.height = max(layoutAttributes.frame.height, size.height)
        }
        if rows.count >= 1 {
            size.width -= minimumInteritemSpacing
        }
        size.width += sectionInset.right
        return size
    }
    
    func allItemWidth(at section: Int) -> CGFloat {
        layoutAttributes.filter({ $0.key.section == section }).values.map(\.frame.width).reduce(0, +)
    }
    
    func maxItemWidth() -> CGFloat {
        layoutAttributes.values.map(\.frame.width).max() ?? 0
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
            let sectionItemWidth = allItemWidth(at: section)
            let rows = rowSequence(in: section)
            
            let sectionInsets = sectionInset.left + sectionInset.right
            let spacings = rows.count >= 1 ? minimumInteritemSpacing * CGFloat(rows.count - 1) : 0
            let availableItemWidth = sectionWidth - sectionInsets - spacings
            
            for row in rows {
                let indexPath = IndexPath(row: row, section: section)
                let layoutAttributes = layoutAttributes[indexPath]!
                let proportionalRatio = layoutAttributes.frame.width / sectionItemWidth
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
