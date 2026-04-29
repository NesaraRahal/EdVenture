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
    var dailyGoalMinutes: Int
    var dailyProgressSeconds: Int
    var isEmailVerified: Bool
    // Stats
    var currentStreak: Int
    var totalXP: Int
    var accuracyPercent: Int
    var quizzesCompleted: Int
    var strongestSubject: String

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
        dailyGoalMinutes: 10,
        dailyProgressSeconds: 0,
        isEmailVerified: false,
        currentStreak: 0,
        totalXP: 0,
        accuracyPercent: 0,
        quizzesCompleted: 0,
        strongestSubject: ""
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
         dailyGoalMinutes: Int,
         dailyProgressSeconds: Int,
            isEmailVerified: Bool,
            currentStreak: Int = 0,
            totalXP: Int = 0,
            accuracyPercent: Int = 0,
            quizzesCompleted: Int = 0,
            strongestSubject: String = "") {
        self.fullName = fullName
        self.username = username
        self.email = email
        self.phone = phone
        self.bio = bio
        self.interests = interests
        self.profileImagePath = profileImagePath
        self.profileImageURL = profileImageURL
        self.profileImageBase64 = profileImageBase64
        self.dailyGoalMinutes = dailyGoalMinutes
        self.dailyProgressSeconds = dailyProgressSeconds
        self.isEmailVerified = isEmailVerified
        self.currentStreak = currentStreak
        self.totalXP = totalXP
        self.accuracyPercent = accuracyPercent
        self.quizzesCompleted = quizzesCompleted
        self.strongestSubject = strongestSubject
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
        self.dailyGoalMinutes = data["dailyGoalMinutes"] as? Int ?? 10
        self.dailyProgressSeconds = data["dailyProgressSeconds"] as? Int ?? 0
        self.isEmailVerified = data["isEmailVerified"] as? Bool ?? verified
        self.currentStreak = data["currentQuizStreak"] as? Int ?? 0
        self.totalXP = data["totalXP"] as? Int ?? 0
        self.accuracyPercent = data["accuracyPercent"] as? Int ?? 0
        self.quizzesCompleted = data["quizzesCompleted"] as? Int ?? 0
        self.strongestSubject = data["strongestSubject"] as? String ?? ""
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
            "dailyGoalMinutes": dailyGoalMinutes,
            "dailyProgressSeconds": dailyProgressSeconds,
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
                    dailyGoalMinutes: 10,
                    dailyProgressSeconds: 0,
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
        
        // Calculate stats from quiz attempts
        await calculateStats(userId: user.uid)
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

        guard let data = image.jpegData(compressionQuality: 0.8) else {
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
            if let fallbackData = image.jpegData(compressionQuality: 0.45) {
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

    private func calculateStats(userId: String) async {
        do {
            let attemptsSnapshot = try await db.collection("users")
                .document(userId)
                .collection("quizAttempts")
                .getDocuments()

            var totalCorrect = 0
            var totalAttempts = 0
            var totalXP = 0
            var lessonAttempts: [String: (correct: Int, total: Int)] = [:]

            for doc in attemptsSnapshot.documents {
                let data = doc.data()
                let isCorrect = data["isCorrect"] as? Bool ?? false
                let earnedXP = data["earnedXP"] as? Int ?? 0
                let lessonId = data["lessonId"] as? String ?? "general"

                totalAttempts += 1
                totalXP += earnedXP

                if isCorrect {
                    totalCorrect += 1
                }

                if lessonAttempts[lessonId] == nil {
                    lessonAttempts[lessonId] = (correct: 0, total: 0)
                }
                lessonAttempts[lessonId]?.total += 1
                if isCorrect {
                    lessonAttempts[lessonId]?.correct += 1
                }
            }

            let accuracy = totalAttempts > 0 ? (totalCorrect * 100) / totalAttempts : 0

            var strongestSubject = ""
            var bestAccuracy = 0
            for (lesson, stats) in lessonAttempts {
                let lessonAccuracy = stats.total > 0 ? (stats.correct * 100) / stats.total : 0
                if lessonAccuracy > bestAccuracy {
                    bestAccuracy = lessonAccuracy
                    strongestSubject = lesson.replacingOccurrences(of: "_", with: " ").capitalized
                }
            }

            let sessionsSnapshot = try await db.collection("users")
                .document(userId)
                .collection("quizSessions")
                .getDocuments()

            var maxStreak = 0
            for doc in sessionsSnapshot.documents {
                let data = doc.data()
                if let streak = data["consecutiveWins"] as? Int {
                    maxStreak = max(maxStreak, streak)
                }
            }

            profile.totalXP = totalXP
            profile.accuracyPercent = accuracy
            profile.quizzesCompleted = totalAttempts
            profile.currentStreak = maxStreak
            profile.strongestSubject = strongestSubject

            try await db.collection("users").document(userId).setData([
                "totalXP": totalXP,
                "accuracyPercent": accuracy,
                "quizzesCompleted": totalAttempts,
                "currentQuizStreak": maxStreak,
                "strongestSubject": strongestSubject,
                "statsUpdatedAt": Timestamp(date: Date())
            ], merge: true)
        } catch {
            print("Failed to calculate stats: \(error.localizedDescription)")
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
