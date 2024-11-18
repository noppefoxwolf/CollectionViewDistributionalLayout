import Testing
import UIKit
@testable import CollectionViewDistributionalLayout

@Suite
struct LayoutAttributesStorageTests {
    @MainActor
    @Test
    func example() {
        let storage = LayoutAttributesStorage()
        let indexPath00 = IndexPath(row: 0, section: 0)
        storage.layoutAttributes[indexPath00] = LayoutAttributes(
            distribution: nil,
            x: 0,
            width: 225,
            zIndex: 0
        )
        let indexPath10 = IndexPath(row: 1, section: 0)
        storage.layoutAttributes[indexPath10] = LayoutAttributes(
            distribution: nil,
            x: 0,
            width: 75,
            zIndex: 0
        )
        storage.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 600, height: 600),
            collectionViewLayout: UICollectionViewLayout()
        )
        #expect(collectionView.safeAreaInsets.left == 0)
        #expect(collectionView.safeAreaInsets.right == 0)
        let sizes = storage.proportionalItemSizes(of: collectionView)
        #expect(sizes[indexPath00] == 420)
        #expect(sizes[indexPath10] == 140)
        
        let width = [
            collectionView.safeAreaInsets.left,
            storage.sectionInset.left,
            sizes[indexPath00]!,
            sizes[indexPath10]!,
            storage.sectionInset.right,
            collectionView.safeAreaInsets.right
        ].reduce(0, +)
        
        #expect(width == 600)
    }
}
