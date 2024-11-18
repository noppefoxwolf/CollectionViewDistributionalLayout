import Testing
import UIKit
@testable import CollectionViewDistributionalLayout

@Suite
struct CollectionViewDistributionalLayoutTests {
    
    @MainActor
    @Test
    func testAutomaticSize() {
        let expectSize = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
        #expect(UICollectionViewFlowLayout.automaticSize == expectSize)
    }
    
    @Test
    func testBoundsInset() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        let frame = bounds.inset(by: insets)
        #expect(frame.origin.x == 5)
        #expect(frame.origin.y == 5)
        #expect(frame.size.width == 90)
        #expect(frame.size.height == 90)
    }
}
