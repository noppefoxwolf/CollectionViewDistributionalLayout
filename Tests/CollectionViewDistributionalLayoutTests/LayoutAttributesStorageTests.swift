import Testing
import UIKit
@testable import CollectionViewDistributionalLayout

@Suite
struct LayoutAttributesStorageTestsFixed {
    @MainActor
    @Test
    func proportionalItemSizes() {
        let storage = LayoutAttributesStorage()
        storage.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        storage.minimumInteritemSpacing = 10
        
        let indexPath00 = IndexPath(row: 0, section: 0)
        storage.layoutAttributes[indexPath00] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 225, height: 500),
            zIndex: 0
        )
        let indexPath10 = IndexPath(row: 1, section: 0)
        storage.layoutAttributes[indexPath10] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 75, height: 500),
            zIndex: 0
        )
        
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 600, height: 600),
            collectionViewLayout: UICollectionViewLayout()
        )
        #expect(collectionView.safeAreaInsets.left == 0)
        #expect(collectionView.safeAreaInsets.right == 0)
        let sizes = storage.proportionalItemSizes(of: collectionView)
        
        let expectWidth00: CGFloat = (600.0 - 20.0 - 20.0 - 10.0) * (225.0 / (225.0 + 75.0))
        #expect(sizes[indexPath00] == expectWidth00)
        
        let expectWidth10: CGFloat = (600.0 - 20.0 - 20.0 - 10.0) * (75.0 / (225.0 + 75.0))
        #expect(sizes[indexPath10] == expectWidth10)
        
        let width = [
            collectionView.safeAreaInsets.left,
            storage.sectionInset.left,
            sizes[indexPath00]!,
            storage.minimumInteritemSpacing,
            sizes[indexPath10]!,
            storage.sectionInset.right,
            collectionView.safeAreaInsets.right
        ].reduce(0, +)
        
        #expect(width == 600)
        
        let indexPath11 = IndexPath(row: 1, section: 1)
        storage.layoutAttributes[indexPath11] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 75, height: 500),
            zIndex: 0
        )
        let sizes2 = storage.proportionalItemSizes(of: collectionView)
        
        let width2 = [
            collectionView.safeAreaInsets.left,
            storage.sectionInset.left,
            sizes2[indexPath00]!,
            storage.minimumInteritemSpacing,
            sizes2[indexPath10]!,
            storage.sectionInset.right,
            storage.sectionInset.left,
            sizes2[indexPath11]!,
            storage.sectionInset.right,
            collectionView.safeAreaInsets.right
        ].reduce(0, +)
        
        #expect(width2 == 600)
    }
    
    @MainActor
    @Test
    func equalItemWidth() {
        let storage = LayoutAttributesStorage()
        storage.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        storage.minimumInteritemSpacing = 10
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 600, height: 600),
            collectionViewLayout: UICollectionViewLayout()
        )
        
        let indexPath00 = IndexPath(row: 0, section: 0)
        storage.layoutAttributes[indexPath00] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 225, height: 500),
            zIndex: 0
        )
        let indexPath10 = IndexPath(row: 1, section: 0)
        storage.layoutAttributes[indexPath10] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 75, height: 500),
            zIndex: 0
        )
        
        let equalItemWidth = storage.equalItemWidth(of: collectionView)
        let expectEqualItemWidth: CGFloat = (600.0 - 20.0 - 10.0 - 20.0) / 2
        #expect(equalItemWidth == expectEqualItemWidth)
        
        let indexPath11 = IndexPath(row: 1, section: 1)
        storage.layoutAttributes[indexPath11] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 75, height: 500),
            zIndex: 0
        )
        
        let equalItemWidth2 = storage.equalItemWidth(of: collectionView)
        let expectEqualItemWidth2: CGFloat = (600.0 - 20.0 - 10.0 - 20.0 - 20.0 - 20.0) / 3
        #expect(equalItemWidth2 == expectEqualItemWidth2)
    }
    
    @MainActor
    @Test
    func dictionarySpec() {
        let storage = LayoutAttributesStorage()
        storage.layoutAttributes[IndexPath(row: 2, section: 0)] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 225, height: 500),
            zIndex: 0
        )
        storage.layoutAttributes[IndexPath(row: 1, section: 0)] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 225, height: 500),
            zIndex: 0
        )
        storage.layoutAttributes[IndexPath(row: 0, section: 1)] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 225, height: 500),
            zIndex: 0
        )
        // 通常のDictionaryなので順序は保証されないが、要素は存在する
        #expect(storage.layoutAttributes[IndexPath(row: 2, section: 0)] != nil)
        #expect(storage.layoutAttributes[IndexPath(row: 1, section: 0)] != nil)
        #expect(storage.layoutAttributes[IndexPath(row: 0, section: 1)] != nil)
        #expect(storage.layoutAttributes.count == 3)
    }
    
    @MainActor
    @Test
    func testContentSize() {
        let storage = LayoutAttributesStorage()
        storage.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        storage.minimumInteritemSpacing = 10
        
        let indexPath00 = IndexPath(row: 0, section: 0)
        storage.layoutAttributes[indexPath00] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 225, height: 500),
            zIndex: 0
        )
        let width1: CGFloat = [20, 225, 20].reduce(0, +)
        #expect(storage.contentSize(preferredSize: false).width == width1)
        
        let indexPath10 = IndexPath(row: 1, section: 0)
        storage.layoutAttributes[indexPath10] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 100, height: 500),
            zIndex: 0
        )
        let width2: CGFloat = [20, 225, 10, 100, 20].reduce(0, +)
        #expect(storage.contentSize(preferredSize: false).width == width2)
    }
    
    @Test
    func sequence() {
        let storage = LayoutAttributesStorage()
        let indexPath10 = IndexPath(row: 1, section: 4)
        storage.layoutAttributes[indexPath10] = LayoutAttributes(
            frame: CGRect(x: 0, y: 0, width: 100, height: 500),
            zIndex: 0
        )
        #expect(storage.sectionSequence().first == 4)
        #expect(storage.rowSequence(in: 4).first == 1)
    }
}