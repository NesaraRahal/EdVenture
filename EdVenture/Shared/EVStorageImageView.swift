import SwiftUI
import FirebaseStorage

struct EVStorageImageView<Placeholder: View>: View {
    let path: String
    let placeholder: Placeholder

    @State private var uiImage: UIImage?

    init(path: String, @ViewBuilder placeholder: () -> Placeholder) {
        self.path = path
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .task(id: path) {
            guard !path.isEmpty else {
                uiImage = nil
                return
            }

            do {
                let data = try await Storage.storage().reference(withPath: path).data(maxSize: 6 * 1024 * 1024)
                uiImage = UIImage(data: data)
            } catch {
                uiImage = nil
            }
        }
    }
}
