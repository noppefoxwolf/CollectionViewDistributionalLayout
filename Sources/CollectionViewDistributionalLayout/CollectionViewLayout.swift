import UIKit

open class CollectionViewLayout: UICollectionViewLayout {
    
    private var internalCollectionViewContentSize: CGSize = .zero
    private lazy var lastPreparedCollectionViewSize: CGSize = collectionView?.bounds.size ?? .zero
    
    open override internal(set) var collectionViewContentSize: CGSize {
        get { internalCollectionViewContentSize }
        set { internalCollectionViewContentSize = newValue }
    }
    
    open override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        if lastPreparedCollectionViewSize != collectionView.bounds.size {
            didChangedCollectionViewSize(collectionView.bounds.size)
            lastPreparedCollectionViewSize = collectionView.bounds.size
        }
    }
    
    open func didChangedCollectionViewSize(_ newSize: CGSize) {
        
    }
}
