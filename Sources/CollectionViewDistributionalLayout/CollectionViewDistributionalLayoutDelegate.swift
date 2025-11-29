import Foundation

@MainActor
public protocol CollectionViewDistributionalLayoutDelegate: AnyObject {
    func collectionViewDistributionalLayout(
        _ layout: CollectionViewDistributionalLayout,
        didUpdateDistribution distribution: Distribution
    )
}
