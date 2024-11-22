import UIKit

open class CollectionViewLayout: UICollectionViewLayout {
    
    private var _collectionViewContentSize: CGSize = .zero
    private lazy var preparedCollectionViewSize: CGSize = collectionView?.bounds.size ?? .zero
    
    open override internal(set) var collectionViewContentSize: CGSize {
        get { _collectionViewContentSize }
        set { _collectionViewContentSize = newValue }
    }
    
    open override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        if preparedCollectionViewSize != collectionView.bounds.size {
            didChangedCollectionViewSize(collectionView.bounds.size)
            preparedCollectionViewSize = collectionView.bounds.size
        }
    }
    
    open func didChangedCollectionViewSize(_ newSize: CGSize) {
        
    }
}
