import Foundation

/// High-performance cache for layout calculations to avoid repeated computations
final class LayoutCache {
    private var cachedSectionSequence: [Int]?
    private var cachedRowSequences: [Int: [Int]] = [:]
    private var cachedSectionSizes: [Int: CGSize] = [:]
    private var cachedContentSize: CGSize?
    private var cachedAllItemWidths: [Int: CGFloat] = [:]
    private var cachedMaxItemWidth: CGFloat?
    private var cachedEqualItemWidth: CGFloat?
    private var cachedProportionalSizes: [IndexPath: CGFloat] = [:]
    
    /// Clears all cached values
    func invalidateAll() {
        cachedSectionSequence = nil
        cachedRowSequences.removeAll()
        cachedSectionSizes.removeAll()
        cachedContentSize = nil
        cachedAllItemWidths.removeAll()
        cachedMaxItemWidth = nil
        cachedEqualItemWidth = nil
        cachedProportionalSizes.removeAll()
    }
    
    // MARK: - Section Sequence Cache
    
    func sectionSequence(compute: () -> [Int]) -> [Int] {
        if let cached = cachedSectionSequence {
            return cached
        }
        let result = compute()
        cachedSectionSequence = result
        return result
    }
    
    // MARK: - Row Sequence Cache
    
    func rowSequence(for section: Int, compute: () -> [Int]) -> [Int] {
        if let cached = cachedRowSequences[section] {
            return cached
        }
        let result = compute()
        cachedRowSequences[section] = result
        return result
    }
    
    // MARK: - Section Size Cache
    
    func sectionSize(for section: Int, preferredSize: Bool, compute: () -> CGSize) -> CGSize {
        let key = section // We could extend this to include preferredSize in the key if needed
        if let cached = cachedSectionSizes[key] {
            return cached
        }
        let result = compute()
        cachedSectionSizes[key] = result
        return result
    }
    
    // MARK: - Content Size Cache
    
    func contentSize(preferredSize: Bool, compute: () -> CGSize) -> CGSize {
        if let cached = cachedContentSize {
            return cached
        }
        let result = compute()
        cachedContentSize = result
        return result
    }
    
    // MARK: - All Item Width Cache
    
    func allItemWidth(for section: Int, compute: () -> CGFloat) -> CGFloat {
        if let cached = cachedAllItemWidths[section] {
            return cached
        }
        let result = compute()
        cachedAllItemWidths[section] = result
        return result
    }
    
    // MARK: - Max Item Width Cache
    
    func maxItemWidth(compute: () -> CGFloat) -> CGFloat {
        if let cached = cachedMaxItemWidth {
            return cached
        }
        let result = compute()
        cachedMaxItemWidth = result
        return result
    }
    
    // MARK: - Equal Item Width Cache
    
    func equalItemWidth(compute: () -> CGFloat) -> CGFloat {
        if let cached = cachedEqualItemWidth {
            return cached
        }
        let result = compute()
        cachedEqualItemWidth = result
        return result
    }
    
    // MARK: - Proportional Sizes Cache
    
    func proportionalItemSizes(compute: () -> [IndexPath: CGFloat]) -> [IndexPath: CGFloat] {
        if !cachedProportionalSizes.isEmpty {
            return cachedProportionalSizes
        }
        let result = compute()
        cachedProportionalSizes = result
        return result
    }
}