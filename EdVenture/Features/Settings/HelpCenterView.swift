import SwiftUI
import FirebaseFirestore
import Combine

struct HelpCenterView: View {
    var onBack: (() -> Void)?

    @StateObject private var vm = HelpCenterViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    topBar
                        .padding(.top, 52)
                        .padding(.horizontal, 20)

                    Text("Help Center")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)

                    if vm.isLoading {
                        ProgressView()
                            .tint(Color(hex: "0EB060"))
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.articles) { article in
                                DisclosureGroup {
                                    Text(article.answer)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.white.opacity(0.72))
                                        .padding(.top, 6)
                                } label: {
                                    Text(article.question)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "FF453A"))
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 24)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.loadArticles()
        }
    }

    private var topBar: some View {
        HStack {
            EVBackButton(title: "Back", action: { onBack?() }, compactTitleSize: 15)

            Spacer()
        }
    }
}

struct HelpArticle: Identifiable {
    let id: String
    let question: String
    let answer: String
}

@MainActor
final class HelpCenterViewModel: ObservableObject {
    @Published var articles: [HelpArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadArticles() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("helpCenterArticles")
                .order(by: "order", descending: false)
                .getDocuments()

            let mapped = snapshot.documents.compactMap { doc -> HelpArticle? in
                let data = doc.data()
                guard
                    let question = data["question"] as? String,
                    let answer = data["answer"] as? String
                else {
                    return nil
                }

                return HelpArticle(id: doc.documentID, question: question, answer: answer)
            }

            if mapped.isEmpty {
                articles = fallbackArticles()
            } else {
                articles = mapped
            }
            errorMessage = nil
        } catch {
            articles = fallbackArticles()
            errorMessage = nil
        }
    }

    private func fallbackArticles() -> [HelpArticle] {
        [
            HelpArticle(
                id: "faq-1",
                question: "How do I add a lesson to practice?",
                answer: "Open Lessons, select a lesson card, then tap add to practice. It will appear under Active Lessons."
            ),
            HelpArticle(
                id: "faq-2",
                question: "How is XP calculated?",
                answer: "XP is awarded per correct answer and can vary by question difficulty and suggested XP settings."
            ),
            HelpArticle(
                id: "faq-3",
                question: "Can I edit my profile later?",
                answer: "Yes. Go to Profile, tap edit profile, then save your updated information."
            )
        ]
    }
}

#Preview {
    HelpCenterView()
}
