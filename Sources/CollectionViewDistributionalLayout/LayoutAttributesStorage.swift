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
    
    var isEmpty: Bool { layoutAttributes.isEmpty }
    
    func setEstimatedAttributes(at indexPath: IndexPath, zIndex: Int) {
        layoutAttributes[indexPath] = LayoutAttributes(
            distribution: nil,
            x: sectionInset.left, // shouldInvalidateを呼ばせるために、見える位置に配置する
            width: estimatedItemSize.width,
            zIndex: zIndex
        )
    }
    
    func contentWidth() -> CGFloat {
        let allItemWidth = allItemWidth()
        let sectionCount = layoutAttributes.keys.map(\.section).uniqued().map({ $0 }).count
        let allSectionInsets = CGFloat(sectionCount) * (sectionInset.left + sectionInset.right)
        return allItemWidth + allSectionInsets
    }
    
    func allItemWidth() -> CGFloat {
        layoutAttributes.values.map(\.width).reduce(0, +)
    }
    
    func maxItemWidth() -> CGFloat {
        layoutAttributes.values.map(\.width).max() ?? 0
    }
    
    @MainActor
    func equalItemWidth(of collectionView: UICollectionView) -> CGFloat {
        (collectionView.safeAreaFrame.width - (sectionInset.left + sectionInset.right)) / CGFloat(layoutAttributes.count)
    }
    
    @MainActor
    func proportionalItemSizes(
        of collectionView: UICollectionView
    ) -> OrderedDictionary<IndexPath, CGFloat> {
        let allItemWidth = allItemWidth()
        return layoutAttributes.mapValues { (layoutAttributes) in
            let baseWidth = layoutAttributes.width
            let proportionalRatio = baseWidth / allItemWidth
            let availableItemWidth = collectionView.safeAreaFrame.inset(by: sectionInset).width
            let proportionallyItemWidth = proportionalRatio * availableItemWidth
            return proportionallyItemWidth
        }
    }
}
