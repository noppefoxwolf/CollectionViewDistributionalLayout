import UIKit

extension UICollectionView {
    package var indexPathSequence: some Sequence<IndexPath> {
        sectionSequence.flatMap { section in
            rowSequence(for: section).map { row in
                IndexPath(row: row, section: section)
            }
        }
    }
    
    package var sectionSequence: some Sequence<Int> {
        (0..<numberOfSections)
    }
    
    package func rowSequence(for section: Int) -> some Sequence<Int> {
        let numberOfRows = numberOfItems(inSection: section)
        return (0..<numberOfRows)
    }
}

extension UICollectionView {
    var adjustedContentFrame: CGRect {
        bounds.inset(by: adjustedContentInset)
    }
}
