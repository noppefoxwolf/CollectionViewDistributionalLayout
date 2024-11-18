import UIKit

open class CollectionViewLayout: UICollectionViewLayout {
    
    private var _collectionViewContentSize: CGSize = .zero
    
    open override internal(set) var collectionViewContentSize: CGSize {
        get { _collectionViewContentSize }
        set { _collectionViewContentSize = newValue }
    }
}
