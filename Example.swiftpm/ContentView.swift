import SwiftUI
import CollectionViewDistributionalLayoutSwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SwiftUIExampleView()
                .tabItem {
                    Label("SwiftUI", systemImage: "rectangle.3.group")
                }

            UIKitExampleView()
                .tabItem {
                    Label("UIKit", systemImage: "rectangle.3.group.fill")
                }
        }
    }
}

private struct UIKitExampleView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(
            rootViewController: ViewController(
                collectionViewLayout: UICollectionViewLayout()
            )
        )
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {}
}

private struct SwiftUIExampleView: View {
    @State private var items = DemoItem.samples
    @State private var usesContentInset = false

    var body: some View {
        NavigationStack {
            DistributionalScrollView(
                spacing: 10,
                horizontalInset: 20,
                contentInsets: EdgeInsets(
                    top: 0,
                    leading: usesContentInset ? 24 : 0,
                    bottom: 0,
                    trailing: usesContentInset ? 24 : 0
                )
            ) {
                itemContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.snappy, value: items)
            .animation(.snappy, value: usesContentInset)
            .navigationTitle("Distributional Layout")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        withAnimation(.snappy) {
                            items.append(DemoItem.random())
                        }
                    }

                    Button("Delete", systemImage: "minus") {
                        withAnimation(.snappy) {
                            _ = items.popLast()
                        }
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Toggle("Inset", isOn: $usesContentInset)
                        .labelsHidden()
                }
            }
        }
    }

    @ViewBuilder
    private var itemContent: some View {
        ForEach(items) { item in
            Text(item.text)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 56,
                    alignment: .center
                )
                .background(.blue.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))
                .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }
}

private struct DemoItem: Identifiable, Hashable {
    let id = UUID()
    let text: String

    static let samples = [
        DemoItem(text: "🦊"),
        DemoItem(text: "Business & Finance"),
        DemoItem(text: "Lorem ipsum dolor sit amet consectetur adipiscing elit"),
        DemoItem(text: "Hello, World!")
    ]

    static func random() -> DemoItem {
        DemoItem(text: [
            "🦊",
            "abcdef",
            "Business & Finance",
            "Lorem ipsum dolor sit amet consectetur adipiscing elit"
        ].randomElement()!)
    }
}
