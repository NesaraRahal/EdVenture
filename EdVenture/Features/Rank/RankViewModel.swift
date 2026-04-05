import Foundation
import FirebaseFirestore
import Combine

struct EVLeaderboardEntry: Identifiable {
    let id: String
    let displayName: String
    let totalXP: Int
    let quizXP: Int
    let streak: Int

    init?(id: String, data: [String: Any]) {
        guard let displayName = data["displayName"] as? String else { return nil }
        self.id = id
        self.displayName = displayName
        self.totalXP = data["totalXP"] as? Int ?? 0
        self.quizXP = data["quizXP"] as? Int ?? 0
        self.streak = data["streak"] as? Int ?? 0
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

            entries = snapshot.documents.compactMap { doc in
                EVLeaderboardEntry(id: doc.documentID, data: doc.data())
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
