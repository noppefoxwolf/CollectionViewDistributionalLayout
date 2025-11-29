import UIKit
import os
import CollectionViewDistributionalLayout

enum Section: Int {
    case items
}

struct Item: Hashable {
    let id: UUID = UUID()
    let text: String
}

final class ViewController: UICollectionViewController, CollectionViewDistributionalLayoutDelegate {
    var distributionLabel: UILabel!
    
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    let cellRegistration = UICollectionView.CellRegistration(
        handler: { (cell, indexPath, item: Item) in
            var contentConfiguration = cell.labelConfiguration()
            contentConfiguration.text = item.text
            cell.contentConfiguration = contentConfiguration
        }
    )
    
    lazy var dataSource = UICollectionViewDiffableDataSource<Section, Item>(
        collectionView: collectionView,
        cellProvider: { [unowned self] (collectionView, indexPath, item) in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
    )
    
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    
    let phrases = [
        "🦊",
        "abcdef",
        "Hello, World!",
        "Buisiness & Finance",
        "Lorem ipsum dolor sit amet consectetur adipiscing elit",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = CollectionViewDistributionalLayout()
        layout.delegate = self
//        let layout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = dataSource
        
        // Distribution表示用のラベルを追加
        distributionLabel = UILabel()
        distributionLabel.text = "Distribution: Unknown"
        distributionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        distributionLabel.textColor = .white
        distributionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        distributionLabel.textAlignment = .center
        distributionLabel.layer.cornerRadius = 8
        distributionLabel.clipsToBounds = true
        distributionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(distributionLabel)
        
        NSLayoutConstraint.activate([
            distributionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            distributionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            distributionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            distributionLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // SafeArea デバッグ表示を追加
        let debugView = SafeAreaDebugView()
        debugView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugView)
        NSLayoutConstraint.activate([
            debugView.topAnchor.constraint(equalTo: view.topAnchor),
            debugView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            debugView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            debugView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        snapshot.appendSections([.items])
        snapshot.appendItems([
            .init(text: "Hello, World!"),
            .init(text: "Hello, World!"),
        ])
        dataSource.apply(snapshot, animatingDifferences: false)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "plus"),
                primaryAction: UIAction { [unowned self] _ in
                    let newItem = Item(text: phrases.randomElement()!)
//                    let newItem = Item(text: "abcdef")
                    logger.log("newItem: \(newItem.text)")
                    snapshot.appendItems([newItem], toSection: .items)
                    dataSource.apply(snapshot, animatingDifferences: false)
                }
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "minus"),
                primaryAction: UIAction { [unowned self] _ in
                    if let last = snapshot.itemIdentifiers.last {
                        snapshot.deleteItems([last])
                    }
                    dataSource.apply(snapshot, animatingDifferences: false)
                }
            ),
        ]
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log("didSelectItemAt \(indexPath)")
    }
    
    // MARK: - CollectionViewDistributionalLayoutDelegate
    
    func collectionViewDistributionalLayout(
        _ layout: CollectionViewDistributionalLayout,
        didUpdateDistribution distribution: Distribution
    ) {
        DispatchQueue.main.async {
            self.distributionLabel.text = "Distribution: \(distribution)"
        }
    }
}

