import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import UIKit

struct UserProfile {
    var fullName: String
    var username: String
    var email: String
    var phone: String
    var bio: String
    var interests: [String]
    var profileImagePath: String
    var profileImageURL: String
    var profileImageBase64: String
    var isEmailVerified: Bool

    static let empty = UserProfile(
        fullName: "",
        username: "",
        email: "",
        phone: "",
        bio: "",
        interests: [],
        profileImagePath: "",
        profileImageURL: "",
        profileImageBase64: "",
        isEmailVerified: false
    )

    init(fullName: String,
         username: String,
         email: String,
         phone: String,
         bio: String,
         interests: [String],
         profileImagePath: String,
         profileImageURL: String,
         profileImageBase64: String,
         isEmailVerified: Bool) {
        self.fullName = fullName
        self.username = username
        self.email = email
        self.phone = phone
        self.bio = bio
        self.interests = interests
        self.profileImagePath = profileImagePath
        self.profileImageURL = profileImageURL
        self.profileImageBase64 = profileImageBase64
        self.isEmailVerified = isEmailVerified
    }

    init(data: [String: Any], fallbackEmail: String, fallbackUsername: String, verified: Bool) {
        self.fullName = data["fullName"] as? String ?? fallbackUsername
        self.username = data["username"] as? String ?? fallbackUsername
        self.email = data["email"] as? String ?? fallbackEmail
        self.phone = data["phone"] as? String ?? ""
        self.bio = data["bio"] as? String ?? ""
        self.interests = data["interests"] as? [String] ?? []
        self.profileImagePath = data["profileImagePath"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
        self.profileImageBase64 = data["profileImageBase64"] as? String ?? ""
        self.isEmailVerified = data["isEmailVerified"] as? Bool ?? verified
    }

    var dictionary: [String: Any] {
        [
            "fullName": fullName,
            "username": username,
            "email": email,
            "phone": phone,
            "bio": bio,
            "interests": interests,
            "profileImagePath": profileImagePath,
            "profileImageURL": profileImageURL,
            "profileImageBase64": profileImageBase64,
            "isEmailVerified": isEmailVerified,
            "updatedAt": Timestamp(date: Date())
        ]
    }
}

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = .empty
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func loadProfile() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await user.reload()

            let email = user.email ?? ""
            let username = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
                .nonEmpty ?? email.components(separatedBy: "@").first ?? "Learner"

            let docRef = db.collection("users").document(user.uid)
            let snapshot = try await docRef.getDocument()

            if let data = snapshot.data() {
                profile = UserProfile(
                    data: data,
                    fallbackEmail: email,
                    fallbackUsername: username,
                    verified: user.isEmailVerified
                )
            } else {
                profile = UserProfile(
                    fullName: username,
                    username: username,
                    email: email,
                    phone: "",
                    bio: "",
                    interests: ["General Knowledge"],
                    profileImagePath: "",
                    profileImageURL: "",
                    profileImageBase64: "",
                    isEmailVerified: user.isEmailVerified
                )

                var seedData = profile.dictionary
                seedData["createdAt"] = Timestamp(date: Date())
                try await docRef.setData(seedData, merge: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func saveProfile() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        let trimmedName = profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = profile.username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Full name is required."
            return
        }

        guard !trimmedUsername.isEmpty else {
            errorMessage = "Username is required."
            return
        }

        isSaving = true
        errorMessage = nil
        saveMessage = nil

        do {
            profile.fullName = trimmedName
            profile.username = trimmedUsername
            profile.email = user.email ?? profile.email
            profile.isEmailVerified = user.isEmailVerified

            try await db.collection("users").document(user.uid)
                .setData(profile.dictionary, merge: true)

            let change = user.createProfileChangeRequest()
            change.displayName = profile.username
            try await change.commitChanges()

            saveMessage = "Profile updated successfully."
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    func uploadProfileImage(_ image: UIImage) async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            return
        }

        let preparedImage = makeCenteredSquareImage(from: image)

        guard let data = preparedImage.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process selected image."
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let fileName = "\(user.uid)_\(Int(Date().timeIntervalSince1970)).jpg"
            let ref = storage.reference().child("profileImages/\(fileName)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            try await uploadImageData(data, to: ref, metadata: metadata)

            let path = ref.fullPath
            profile.profileImagePath = path

            let url = try? await fetchDownloadURL(for: ref)
            let urlString = url?.absoluteString ?? profile.profileImageURL
            profile.profileImageURL = urlString

            try await db.collection("users").document(user.uid).setData([
                "profileImagePath": path,
                "profileImageURL": urlString,
                "profileImageBase64": "",
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
        } catch {
            // Fallback: persist a compressed base64 avatar directly in Firestore
            // so profile photos still work if Storage is misconfigured.
            if let fallbackData = preparedImage.jpegData(compressionQuality: 0.45) {
                let base64 = fallbackData.base64EncodedString()
                profile.profileImageBase64 = base64
                profile.profileImagePath = ""
                profile.profileImageURL = ""

                do {
                    try await db.collection("users").document(user.uid).setData([
                        "profileImageBase64": base64,
                        "profileImagePath": "",
                        "profileImageURL": "",
                        "updatedAt": Timestamp(date: Date())
                    ], merge: true)
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isSaving = false
    }

    private func makeCenteredSquareImage(from image: UIImage) -> UIImage {
        let size = image.size
        let length = min(size.width, size.height)
        let origin = CGPoint(
            x: (size.width - length) * 0.5,
            y: (size.height - length) * 0.5
        )
        let cropRect = CGRect(origin: origin, size: CGSize(width: length, height: length))

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func uploadImageData(_ data: Data,
                                 to ref: StorageReference,
                                 metadata: StorageMetadata) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func fetchDownloadURL(for ref: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "UserProfileViewModel",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Download URL is unavailable."]
                    ))
                }
            }
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
