import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit
import Combine

// MARK: - HomeView
// Features/Home/HomeView.swift

struct HomeView: View {

    @StateObject private var vm      = HomeViewModel()
    @State private var appeared      = false
    @State private var challengePage = 0

    // ── Navigation callbacks ─────────────────────────────────────────
    var onLessons:   (() -> Void)?
    var onDiscovery: (() -> Void)?
    var onRank:      (() -> Void)?
    var onSettings:  (() -> Void)?
    var onOpenLesson: ((String) -> Void)?
    var onNotifications: (() -> Void)?
    var onProfile:   (() -> Void)?

    let challenges: [Challenge] = [
        Challenge(
            tag: "TIMED CHALLENGE",
            title: "NEURO-SYNC\nDRIFT",
            description: "Synchronize your neural pathways in this high-intensity cognitive race.",
            gradient: [Color(hex: "4FC3A1"), Color(hex: "3B82C4"), Color(hex: "6C63D8")]
        ),
        Challenge(
            tag: "DAILY QUEST",
            title: "QUANTUM\nLEAP",
            description: "Push your limits across physics, logic and spatial reasoning.",
            gradient: [Color(hex: "F59E0B"), Color(hex: "EF4444"), Color(hex: "8B5CF6")]
        ),
        Challenge(
            tag: "SPEED RUN",
            title: "FLASH\nFACTS",
            description: "60 seconds. 20 questions. How fast can your brain fire?",
            gradient: [Color(hex: "10B981"), Color(hex: "059669"), Color(hex: "0EB060")]
        ),
    ]

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar

                    greeting
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    statsRow
                        .padding(.top, 24)

                    challengeCarousel
                        .padding(.top, 28)

                    activeLessons
                        .padding(.top, 28)
                        .padding(.bottom, 110)
                }
            }

        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { appeared = true }

            Task {
                await vm.refreshDashboardForCurrentUser()
            }
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        EVScreenTopBar(onProfile: onProfile, onNotifications: onNotifications)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: appeared)
    }

    // MARK: - Greeting
    private var greeting: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Hi \(vm.greetingName),")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            Text("Ready to outsmart the clock?")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
    }

    // MARK: - Stats row
    private var statsRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(vm.stats.enumerated()), id: \.element.id) { i, stat in
                StatCard(stat: stat)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.15 + Double(i) * 0.07), value: appeared)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Challenge carousel
    private var challengeCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $challengePage) {
                ForEach(Array(challenges.enumerated()), id: \.element.id) { i, challenge in
                    ChallengeCard(challenge: challenge)
                        .tag(i)
                        .padding(.horizontal, 20)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)

            HStack(spacing: 6) {
                ForEach(0..<challenges.count, id: \.self) { i in
                    Circle()
                        .fill(i == challengePage ? Color.white : Color.white.opacity(0.3))
                        .frame(
                            width:  i == challengePage ? 8 : 6,
                            height: i == challengePage ? 8 : 6
                        )
                        .animation(.easeInOut(duration: 0.2), value: challengePage)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.45).delay(0.28), value: appeared)
    }

    // MARK: - Active lessons
    private var activeLessons: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Active Lessons")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button("SEE ALL") { onLessons?() }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 20)

            if vm.isLoadingActiveLessons {
                ProgressView()
                    .tint(Color(hex: "0EB060"))
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .padding(.horizontal, 20)
            } else if vm.activeLessons.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    Text("No active lessons yet")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))

                    Text("Add lessons to practice from the Lessons tab.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 20)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(Array(vm.activeLessons.enumerated()), id: \.element.id) { i, lesson in
                        Button {
                            onOpenLesson?(lesson.id)
                        } label: {
                            HomeLessonCard(lesson: lesson)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.45).delay(0.34 + Double(i) * 0.07), value: appeared)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

}

// MARK: - Supporting models
struct StatItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
    var isHighlighted: Bool = false
}

struct Challenge: Identifiable {
    let id = UUID()
    let tag: String
    let title: String
    let description: String
    let gradient: [Color]
}

struct HomeActiveLesson: Identifiable {
    let id: String
    let icon: String
    let iconBg: Color
    let title: String
    let subtitle: String
    let progress: Double
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var greetingName = "Learner"
    @Published var stats: [StatItem] = [
        StatItem(icon: "timer", label: "PLAY TIME", value: "0m"),
        StatItem(icon: "person.fill", label: "RANK", value: "Amateur", isHighlighted: true),
        StatItem(icon: "star", label: "ACTIVE", value: "0 Lessons")
    ]
    @Published var activeLessons: [HomeActiveLesson] = []
    @Published var isLoadingActiveLessons = false

    private let db = Firestore.firestore()

    func refreshDashboardForCurrentUser() async {
        guard Auth.auth().currentUser?.uid != nil else {
            greetingName = "Learner"
            activeLessons = []
            stats = [
                StatItem(icon: "timer", label: "PLAY TIME", value: "0m"),
                StatItem(icon: "person.fill", label: "RANK", value: "Amateur", isHighlighted: true),
                StatItem(icon: "star", label: "ACTIVE", value: "0 Lessons")
            ]
            return
        }

        async let lessonsTask: Void = fetchActiveLessonsForCurrentUser()
        async let profileTask: Void = fetchDashboardProfileMetrics()
        _ = await (lessonsTask, profileTask)
    }

    func fetchActiveLessonsForCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            activeLessons = []
            updateStats(activeLessonsCount: 0)
            return
        }

        isLoadingActiveLessons = true
        defer { isLoadingActiveLessons = false }

        do {
            let activeSnapshot = try await db
                .collection("users")
                .document(uid)
                .collection("activeLessons")
                .order(by: "addedAt", descending: true)
                .getDocuments()

            var mapped: [HomeActiveLesson] = []

            for doc in activeSnapshot.documents {
                let lessonId = doc.documentID
                let progress = min(max((doc.data()["progress"] as? Double) ?? 0.0, 0.0), 1.0)

                let lessonDoc = try await db.collection("lessons").document(lessonId).getDocument()
                guard let data = lessonDoc.data() else { continue }

                let title = (data["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let description = (data["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let subtitle = (data["subtitle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let icon = (data["icon"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let colorHex = (data["color"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

                let resolvedIcon = resolveIcon(icon)

                mapped.append(
                    HomeActiveLesson(
                        id: lessonId,
                        icon: resolvedIcon,
                        iconBg: Color(hex: (colorHex?.isEmpty == false ? colorHex! : "0EB060")).opacity(0.2),
                        title: (title?.isEmpty == false ? title! : "Untitled"),
                        subtitle: (subtitle?.isEmpty == false ? subtitle! : shortSubtitle(from: description)),
                        progress: progress
                    )
                )
            }

            activeLessons = mapped
            updateStats(activeLessonsCount: mapped.count)
        } catch {
            activeLessons = []
            updateStats(activeLessonsCount: 0)
        }
    }

    private func fetchDashboardProfileMetrics() async {
        guard let user = Auth.auth().currentUser else {
            greetingName = "Learner"
            return
        }

        do {
            let doc = try await db.collection("users").document(user.uid).getDocument()
            let data = doc.data() ?? [:]

            let fullName = (data["fullName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let username = (data["username"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let authName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)

            let preferredName = [fullName, username, authName]
                .compactMap { $0 }
                .first(where: { !$0.isEmpty }) ?? "Learner"

            greetingName = firstName(
                from: preferredName
            )

            let totalXP = data["totalXP"] as? Int ?? 0
            let totalPlaySeconds = data["totalPlaySeconds"] as? Int ?? 0
            updateStats(totalXP: totalXP, totalPlaySeconds: totalPlaySeconds)
        } catch {
            let authName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
            greetingName = firstName(from: (authName?.isEmpty == false ? authName! : "Learner"))
        }
    }

    private func updateStats(totalXP: Int? = nil,
                             totalPlaySeconds: Int? = nil,
                             activeLessonsCount: Int? = nil) {
        let existingRank = stats.first(where: { $0.label == "RANK" })?.value ?? "Amateur"
        let existingPlay = stats.first(where: { $0.label == "PLAY TIME" })?.value ?? "0m"
        let existingActive = stats.first(where: { $0.label == "ACTIVE" })?.value ?? "0 Lessons"

        let rankTitle = totalXP.map(rankTitleForXP) ?? existingRank
        let playText = totalPlaySeconds.map(formatPlayTime) ?? existingPlay
        let activeText = activeLessonsCount.map { "\($0) Lessons" } ?? existingActive

        stats = [
            StatItem(icon: "timer", label: "PLAY TIME", value: playText),
            StatItem(icon: "person.fill", label: "RANK", value: rankTitle, isHighlighted: true),
            StatItem(icon: "star", label: "ACTIVE", value: activeText)
        ]
    }

    private func firstName(from rawName: String) -> String {
        let cleaned = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return "Learner" }

        let firstToken = cleaned
            .split(whereSeparator: { $0.isWhitespace })
            .first
            .map(String.init)
            ?? cleaned

        return firstToken.prefix(1).uppercased() + firstToken.dropFirst()
    }

    private func rankTitleForXP(_ xp: Int) -> String {
        switch xp {
        case ..<100: return "Amateur"
        case ..<200: return "Adept"
        case ..<400: return "Polymath"
        case ..<700: return "Scholar"
        case ..<1100: return "Strategist"
        case ..<1600: return "Sage"
        case ..<2300: return "Grandmaster"
        default: return "Legend"
        }
    }

    private func formatPlayTime(_ seconds: Int) -> String {
        let safeSeconds = max(seconds, 0)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(max(minutes, 0))m"
    }

    private func resolveIcon(_ icon: String?) -> String {
        let candidate = (icon?.isEmpty == false ? icon! : "book.fill")
        return UIImage(systemName: candidate) == nil ? "book.fill" : candidate
    }

    private func shortSubtitle(from description: String?) -> String {
        guard let text = description, !text.isEmpty else { return "Start learning" }
        if let firstPart = text.components(separatedBy: ".").first,
           !firstPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return firstPart.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}

// MARK: - StatCard
private struct StatCard: View {
    let stat: StatItem

    private var accent: Color {
        switch stat.label {
        case "PLAY TIME": return Color(hex: "F59E0B")
        case "RANK": return Color(hex: "0EB060")
        case "ACTIVE": return Color(hex: "38BDF8")
        default: return Color(hex: "0EB060")
        }
    }

    private var softAccent: Color {
        switch stat.label {
        case "PLAY TIME": return Color(hex: "FDE68A")
        case "RANK": return Color(hex: "86EFAC")
        case "ACTIVE": return Color(hex: "7DD3FC")
        default: return Color.white
        }
    }

    private var iconColor: Color {
        accent
    }

    private var iconBackgroundColor: Color {
        accent.opacity(0.16)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 46, height: 46)

                Circle()
                    .stroke(accent.opacity(0.35), lineWidth: 1)
                    .frame(width: 46, height: 46)

                Image(systemName: stat.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .shadow(color: accent.opacity(0.28), radius: 10, x: 0, y: 3)

            Text(stat.label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1.1)

            Text(stat.value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: softAccent.opacity(0.25), radius: 6, x: 0, y: 1)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.95), softAccent.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 44, height: 4)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 142)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.04),
                                    accent.opacity(0.07)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(accent.opacity(0.38), lineWidth: 1.05)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: accent.opacity(0.16), radius: 14, x: 0, y: 5)
    }
}

// MARK: - ChallengeCard
private struct ChallengeCard: View {
    let challenge: Challenge
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: challenge.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "brain.head.profile")
                .font(.system(size: 120))
                .foregroundColor(.white.opacity(0.07))
                .offset(x: 130, y: -8)
            VStack(alignment: .leading, spacing: 0) {
                Text(challenge.tag)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                Spacer()
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.title)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineSpacing(2)
                        Text(challenge.description)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Join Now") {}
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .fixedSize()
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(height: 200)
    }
}

// MARK: - HomeLessonCard (grid card on home screen)
private struct HomeLessonCard: View {
    let lesson: HomeActiveLesson
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: lesson.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(lesson.progress > 0.5 ? Color(hex: "0EB060") : .white.opacity(0.65))
                .frame(width: 42, height: 42)
                .background(lesson.iconBg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer()
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(lesson.subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.38))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(lesson.progress > 0.5
                              ? Color(hex: "0EB060")
                              : Color.white.opacity(0.28))
                        .frame(width: geo.size.width * lesson.progress, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.top, 10)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 158)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    HomeView()
}
