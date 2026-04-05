import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    @StateObject private var vm = UserProfileViewModel()
    @AppStorage("security.biometricsEnabled") private var biometricsEnabled = false
    @AppStorage("security.requireForProfileChanges") private var requireForProfileChanges = false

    @State private var showingAddInterest = false
    @State private var showingPhotoOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var newInterest = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingErrorAlert = false
    @State private var showingSavedAlert = false

    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    avatarHeader
                        .padding(.top, 26)

                    sectionHeader("Personal Information")
                        .padding(.top, 30)
                        .padding(.horizontal, 20)

                    fields
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    sectionHeader("Learning Preferences")
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    interestsBlock
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    saveButton
                        .padding(.top, 38)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await vm.loadProfile() }
        }
        .confirmationDialog("Profile Photo", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showingCamera = true
                }
            }

            Button("Choose from Library") {
                showingPhotoLibrary = true
            }

            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }

            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraImagePicker(selectedImage: $selectedImage)
        }
        .alert("Add Interest", isPresented: $showingAddInterest) {
            TextField("e.g. Astronomy", text: $newInterest)
            Button("Add") {
                let item = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
                if !item.isEmpty && !vm.profile.interests.contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) {
                    vm.profile.interests.append(item)
                }
                newInterest = ""
            }
            Button("Cancel", role: .cancel) { newInterest = "" }
        } message: {
            Text("Add a topic you want to learn")
        }
        .onChange(of: vm.errorMessage) { _, newValue in
            showingErrorAlert = (newValue != nil)
        }
        .onChange(of: vm.saveMessage) { _, newValue in
            showingSavedAlert = (newValue != nil)
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Saved", isPresented: $showingSavedAlert) {
            Button("OK") { vm.saveMessage = nil }
        } message: {
            Text(vm.saveMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onBack?()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())
            }
            .frame(minWidth: 44, minHeight: 44)

            Spacer()

            Text("Edit Profile")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Color.clear
                .frame(width: 88, height: 44)
        }
    }

    private var avatarHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 148, height: 148)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "2BE292"), lineWidth: 5)
                    )
                    .overlay(
                        Group {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                            } else if !vm.profile.profileImagePath.isEmpty {
                                EVStorageImageView(path: vm.profile.profileImagePath) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 54, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
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
                                            .font(.system(size: 54, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 54, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(width: 136, height: 136)
                        .clipShape(Circle())
                    )
                    .clipShape(Circle())

                Button {
                    showingPhotoOptions = true
                } label: {
                    Circle()
                        .fill(Color(hex: "2BE292"))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "0A0F0D"))
                        )
                        .shadow(color: .black.opacity(0.22), radius: 6, y: 2)
                }
                    .offset(x: -2, y: -2)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .buttonStyle(ScaleButtonStyle())
            }

            Text(vm.profile.fullName.isEmpty ? "Your Name" : vm.profile.fullName)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 20)
        }
    }

    private var fields: some View {
        VStack(spacing: 12) {
            fieldCard(label: "FULL NAME") {
                TextField("Full name", text: $vm.profile.fullName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            fieldCard(label: "USERNAME") {
                TextField("Username", text: $vm.profile.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            fieldCard(label: "EMAIL") {
                HStack {
                    Text(vm.profile.email)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    if vm.profile.isEmailVerified {
                        Label("Verified", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "7EF5A8"))
                    }
                }
            }

            fieldCard(label: "PHONE") {
                TextField("+1 (555) 123-4567", text: $vm.profile.phone)
                    .keyboardType(.phonePad)
            }

            fieldCard(label: "BIO") {
                TextEditor(text: $vm.profile.bio)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
        }
    }

    private var interestsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INTERESTS")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.2)

            FlowLayout(spacing: 10, lineSpacing: 10) {
                ForEach(vm.profile.interests, id: \.self) { interest in
                    HStack(spacing: 8) {
                        Text(interest)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "0A0F0D"))

                        Button {
                            vm.profile.interests.removeAll { $0 == interest }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "0A0F0D"))
                        }
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(Color(hex: "0EB060"))
                    .clipShape(Capsule())
                }

                Button {
                    showingAddInterest = true
                } label: {
                    Text("+ Add")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 28)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                if biometricsEnabled && requireForProfileChanges {
                    let ok = await EVBiometricAuth.authorize(
                        reason: "Authenticate to save profile changes"
                    )

                    if !ok {
                        vm.errorMessage = "Face ID / Touch ID verification failed. Changes were not saved."
                        return
                    }
                }

                if let selectedImage {
                    await vm.uploadProfileImage(selectedImage)
                    if vm.errorMessage != nil {
                        return
                    }
                }

                await vm.saveProfile()

                if vm.errorMessage == nil {
                    self.selectedImage = nil
                }
            }
        } label: {
            ZStack {
                if vm.isSaving {
                    ProgressView()
                        .tint(Color(hex: "0A0F0D"))
                } else {
                    Text("Save Changes")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0A0F0D"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .background(Color(hex: "0EB060"))
            .clipShape(Capsule())
            .shadow(color: Color(hex: "0EB060").opacity(0.3), radius: 16, y: 4)
        }
        .disabled(vm.isSaving || vm.isLoading)
    }

    private func fieldCard<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(1.4)

            content()
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .tint(Color(hex: "0EB060"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: "7EF5A8"))
                .frame(width: 10, height: 40)

            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// Lightweight wrapping layout for interest chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else {
            let width = subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width + spacing }
            let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            return CGSize(width: width, height: height)
        }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }
    }
}

#Preview {
    EditProfileView()
}
