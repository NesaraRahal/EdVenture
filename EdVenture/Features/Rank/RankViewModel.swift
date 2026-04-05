import Foundation
import FirebaseFirestore
import Combine

struct EVLeaderboardEntry: Identifiable {
    let id: String
    let displayName: String
    let totalXP: Int
    let quizXP: Int
    let streak: Int
    let profileImageUrl: String?
    let profileImageBase64: String?

    init(id: String,
         displayName: String,
         totalXP: Int,
         quizXP: Int,
         streak: Int,
         profileImageUrl: String?,
         profileImageBase64: String?) {
        self.id = id
        self.displayName = displayName
        self.totalXP = totalXP
        self.quizXP = quizXP
        self.streak = streak
        self.profileImageUrl = profileImageUrl
        self.profileImageBase64 = profileImageBase64
    }

    init?(id: String, data: [String: Any]) {
        guard let displayName = data["displayName"] as? String else { return nil }
        self.id = id
        self.displayName = displayName
        self.totalXP = data["totalXP"] as? Int ?? 0
        self.quizXP = data["quizXP"] as? Int ?? 0
        self.streak = data["streak"] as? Int ?? 0
        self.profileImageUrl = (data["profileImagePath"] as? String)
            ?? (data["profileImageURL"] as? String)
            ?? (data["profileImageUrl"] as? String)
        self.profileImageBase64 = data["profileImageBase64"] as? String
    }

    func withProfileImage(source: String?, base64: String?) -> EVLeaderboardEntry {
        EVLeaderboardEntry(
            id: id,
            displayName: displayName,
            totalXP: totalXP,
            quizXP: quizXP,
            streak: streak,
            profileImageUrl: source,
            profileImageBase64: base64
        )
    }
}

@MainActor
final class RankViewModel: ObservableObject {
    @Published var entries: [EVLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let snapshot = try await db
                .collection("leaderboards")
                .document("global")
                .collection("entries")
                .order(by: "totalXP", descending: true)
                .limit(to: 10)
                .getDocuments()

            let baseEntries = snapshot.documents.compactMap { doc in
                EVLeaderboardEntry(id: doc.documentID, data: doc.data())
            }

            let uidList = baseEntries.map(\.id)
            let profilesByUid = await loadProfileAssetsByUid(uids: uidList)

            entries = baseEntries.map { entry in
                let hasSource = (entry.profileImageUrl?.isEmpty == false)
                let hasBase64 = (entry.profileImageBase64?.isEmpty == false)
                if hasSource || hasBase64 {
                    return entry
                }

                guard let asset = profilesByUid[entry.id] else { return entry }
                return entry.withProfileImage(source: asset.source, base64: asset.base64)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProfileAssetsByUid(uids: [String]) async -> [String: (source: String?, base64: String?)] {
        guard !uids.isEmpty else { return [:] }

        var result: [String: (source: String?, base64: String?)] = [:]

        for uid in uids {
            do {
                let snapshot = try await db.collection("users").document(uid).getDocument()
                guard let data = snapshot.data() else { continue }

                let source = (data["profileImagePath"] as? String)
                    ?? (data["profileImageURL"] as? String)
                    ?? (data["profileImageUrl"] as? String)
                let base64 = data["profileImageBase64"] as? String

                let hasSource = source?.isEmpty == false
                let hasBase64 = base64?.isEmpty == false
                if hasSource || hasBase64 {
                    result[uid] = (source, base64)
                }
            } catch {
                continue
            }
        }

        return result
    }
}
