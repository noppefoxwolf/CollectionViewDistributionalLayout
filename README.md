# CollectionViewDistributionalLayout

A UICollectionViewLayout subclass to distribute cells in a collection view with a distribution algorithm.

![](https://github.com/noppefoxwolf/CollectionViewDistributionalLayout/blob/main/.github/screenshot.gif)

## Anatomy

```mermaid
flowchart TD;
A[Invalidate layout] --> B[Self-size cells];
B --> C[Check item sizes];
C -- Enougth width --> D[Can be equal width without compress?];
C -- Not enough width --> E[Scrollable fill layout];
D -- YES --> F[Fill items equally layout];
D -- NO --> G[Fill items proportinally layout];
```

## Usage

```swift
let layout = CollectionViewDistributionalLayout()
collectionView.collectionViewLayout = layout
```

## Installation

```swift
.dependencies: [
    .package(
        url: "https://github.com/noppefoxwolf/CollectionViewDistributionalLayout.git", 
        from: "0.0.x"
    )
]
```

## License

CollectionViewDistributionalLayout is available under the MIT license. See the LICENSE file for more info.
