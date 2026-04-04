import SwiftUI

struct EVProfileAvatarView: View {
    @StateObject private var vm = UserProfileViewModel()

    var size: CGFloat = 38
    var iconSize: CGFloat = 15
    var iconOpacity: Double = 0.7
    var ringColor: Color = Color.white.opacity(0.15)
    var ringWidth: CGFloat = 0.5

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.12))
            .frame(width: size, height: size)
            .overlay {
                Group {
                    if !vm.profile.profileImagePath.isEmpty {
                        EVStorageImageView(path: vm.profile.profileImagePath) {
                            Image(systemName: "person.fill")
                                .font(.system(size: iconSize, weight: .medium))
                                .foregroundColor(.white.opacity(iconOpacity))
                        }
                    } else if let data = Data(base64Encoded: vm.profile.profileImageBase64),
                              let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let url = URL(string: vm.profile.profileImageURL), !vm.profile.profileImageURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Image(systemName: "person.fill")
                                    .font(.system(size: iconSize, weight: .medium))
                                    .foregroundColor(.white.opacity(iconOpacity))
                            }
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: iconSize, weight: .medium))
                            .foregroundColor(.white.opacity(iconOpacity))
                    }
                }
                .clipShape(Circle())
            }
            .overlay(Circle().stroke(ringColor, lineWidth: ringWidth))
            .task {
                if vm.profile.profileImageURL.isEmpty {
                    await vm.loadProfile()
                }
            }
    }
}
