import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct PreferencesOnboardingView: View {
    var onCompleted: (() -> Void)?

    @StateObject private var vm = PreferencesOnboardingViewModel()

    var body: some View {
        ZStack {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Tailor Your Journey")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 56)

                    Text("Select your preferences to personalize your experience.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text("What are you interested in?")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))

                    if vm.isLoadingCategories {
                        ProgressView()
                            .tint(Color(hex: "0EB060"))
                    } else {
                        chipFlow
                    }

                    Text("Set Your Daily Goal")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "7EF5A8"))

                    goalSelection

                    if let errorMessage = vm.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "FF453A"))
                    }

                    Button {
                        Task {
                            await vm.save()
                            if vm.errorMessage == nil {
                                onCompleted?()
                            }
                        }
                    } label: {
                        ZStack {
                            if vm.isSaving {
                                ProgressView()
                                    .tint(Color(hex: "0A0F0D"))
                            } else {
                                Text("Verify & Continue")
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
                    .disabled(vm.selectedInterests.isEmpty || vm.isSaving)
                    .opacity(vm.selectedInterests.isEmpty ? 0.7 : 1)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.loadCategories()
        }
    }

    private var chipFlow: some View {
        FlowLayout(spacing: 10, lineSpacing: 10) {
            ForEach(vm.categories, id: \.self) { category in
                let selected = vm.selectedInterests.contains(category)

                Button {
                    vm.toggleCategory(category)
                } label: {
                    Text(category)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(selected ? Color(hex: "0A0F0D") : .white.opacity(0.72))
                        .padding(.horizontal, 22)
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(selected ? Color(hex: "0EB060") : Color.white.opacity(0.08))
                        )
                        .overlay(
                            Capsule()
                                .stroke(selected ? Color.clear : Color.white.opacity(0.15), lineWidth: 0.8)
                        )
                        .shadow(color: selected ? Color(hex: "0EB060").opacity(0.35) : .clear, radius: 10, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private var goalSelection: some View {
        HStack(spacing: 14) {
            ForEach([5, 10, 15], id: \.self) { goal in
                let selected = vm.dailyGoalMinutes == goal

                VStack(spacing: 8) {
                    if goal == 10 {
                        Text("POPULAR")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "0A0F0D"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: "0EB060"))
                            .clipShape(Capsule())
                            .opacity(goal == 10 ? 1 : 0)
                    }

                    VStack(spacing: 4) {
                        Text("\(goal)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundColor(selected ? Color(hex: "0EB060") : .white.opacity(0.88))

                        Text("MINUTES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selected ? Color(hex: "0EB060") : .white.opacity(0.52))
                            .tracking(1.1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 144)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(selected ? Color(hex: "0EB060") : Color.white.opacity(0.08), lineWidth: selected ? 1.8 : 0.8)
                            )
                    )
                }
                .onTapGesture {
                    vm.dailyGoalMinutes = goal
                }
            }
        }
    }
}

@MainActor
final class PreferencesOnboardingViewModel: ObservableObject {
    @Published var categories: [String] = []
    @Published var selectedInterests: Set<String> = []
    @Published var dailyGoalMinutes: Int = 10
    @Published var isLoadingCategories = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadCategories() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "Please sign in to continue."
            return
        }

        isLoadingCategories = true
        defer { isLoadingCategories = false }

        do {
            let snapshot = try await db.collection("lessons")
                .order(by: "order")
                .getDocuments()

            let lessonTitles = snapshot.documents.compactMap { doc -> String? in
                let title = (doc.data()["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let title, !title.isEmpty else { return nil }
                return title
            }

            let normalized = Array(NSOrderedSet(array: lessonTitles)).compactMap { $0 as? String }
            categories = normalized.isEmpty ? ["Math", "Science", "Technology", "Philosophy", "Computing", "Astronomy"] : normalized

            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let data = userDoc.data() ?? [:]
            let existingInterests = data["interests"] as? [String] ?? []
            let existingGoal = data["dailyGoalMinutes"] as? Int ?? 10

            selectedInterests = Set(existingInterests.isEmpty ? Array(categories.prefix(2)) : existingInterests)
            dailyGoalMinutes = existingGoal
            errorMessage = nil
        } catch {
            categories = ["Math", "Science", "Technology", "Philosophy", "Computing", "Astronomy"]
            if selectedInterests.isEmpty {
                selectedInterests = ["Math", "Technology"]
            }
            errorMessage = nil
        }
    }

    func toggleCategory(_ category: String) {
        if selectedInterests.contains(category) {
            if selectedInterests.count > 1 {
                selectedInterests.remove(category)
            }
        } else {
            selectedInterests.insert(category)
        }
    }

    func save() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to continue."
            return
        }

        guard !selectedInterests.isEmpty else {
            errorMessage = "Select at least one interest."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await db.collection("users").document(uid).setData([
                "interests": Array(selectedInterests).sorted(),
                "dailyGoalMinutes": dailyGoalMinutes,
                "dailyProgressSeconds": 0,
                "dailyProgressDate": dayKey(Date()),
                "dailyGoalCompleted": false,
                "onboardingPreferencesCompleted": true,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)

            await EVNotificationService.shared.refreshDailyGoalReminderForCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    PreferencesOnboardingView()
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else {
            let widths = subviews.map { $0.sizeThatFits(.unspecified).width }
            let heights = subviews.map { $0.sizeThatFits(.unspecified).height }
            return CGSize(width: widths.reduce(0, +), height: heights.max() ?? 0)
        }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
