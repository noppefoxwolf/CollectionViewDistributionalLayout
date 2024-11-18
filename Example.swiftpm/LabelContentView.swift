import UIKit

final class LabelContentView: UIView, UIContentView {
    struct Configuration: UIContentConfiguration {
        var text: String? = nil

        func makeContentView() -> UIView & UIContentView {
            LabelContentView(self)
        }

        func updated(for state: UIConfigurationState) -> LabelContentView.Configuration {
            self
        }
    }

    private let label = UILabel()
    var configuration: UIContentConfiguration {
        didSet {
            configure(configuration: configuration)
        }
    }

    init(_ configuration: UIContentConfiguration) {
        self.configuration = configuration

        super.init(frame: .zero)
        
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 64),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(configuration: UIContentConfiguration) {
        guard let configuration = configuration as? Configuration else { return }
        label.text = configuration.text
    }
}

extension UICollectionViewCell {
    func labelConfiguration() -> LabelContentView.Configuration {
        LabelContentView.Configuration()
    }
}
