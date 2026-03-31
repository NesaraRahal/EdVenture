//
//  HomeView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-03-31.
//


//
//  HomeView.swift
//  EdVenture
//
//  Features/Home/HomeView.swift

import SwiftUI

// MARK: - Models
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

struct Lesson: Identifiable {
    let id = UUID()
    let icon: String
    let iconBg: Color
    let title: String
    let subtitle: String
    let progress: Double
}

// MARK: - HomeView
struct HomeView: View {

    @State private var appeared      = false
    @State private var selectedTab   = 0
    @State private var challengePage = 0

    let stats: [StatItem] = [
        StatItem(icon: "timer",       label: "PLAY TIME", value: "2 Hours"),
        StatItem(icon: "person.fill", label: "RANK",      value: "Polymath", isHighlighted: true),
        StatItem(icon: "star",        label: "ACTIVE",    value: "10 Lessons"),
    ]

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

    let lessons: [Lesson] = [
        Lesson(icon: "airplane",          iconBg: Color(hex: "0EB060").opacity(0.2), title: "Astronomy",  subtitle: "Stellar Evolution", progress: 0.72),
        Lesson(icon: "book.fill",         iconBg: Color.white.opacity(0.08),         title: "Philosophy", subtitle: "Stoic Principles",  progress: 0.35),
        Lesson(icon: "square.grid.2x2",   iconBg: Color.white.opacity(0.08),         title: "Computing",  subtitle: "Quantum Logic",     progress: 0.18),
        Lesson(icon: "staroflife.fill",   iconBg: Color.white.opacity(0.08),         title: "Biology",    subtitle: "Helix Mapping",     progress: 0.28),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

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

            tabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("EdVentureLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("EdVenture")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
            }
            Spacer()
            HStack(spacing: 14) {
                Button {} label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: appeared)
    }

    // MARK: - Greeting
    private var greeting: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Hi Nesara,")
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
            ForEach(Array(stats.enumerated()), id: \.element.id) { i, stat in
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
                Button("SEE ALL") {}
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "0EB060"))
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 20)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(Array(lessons.enumerated()), id: \.element.id) { i, lesson in
                    LessonCard(lesson: lesson)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.45).delay(0.34 + Double(i) * 0.07), value: appeared)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Tab bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.offset) { i, item in
                Button { selectedTab = i } label: {
                    VStack(spacing: 4) {
                        if i == 0 {
                            ZStack {
                                Capsule()
                                    .fill(Color(hex: "0EB060"))
                                    .frame(width: 52, height: 36)
                                Image(systemName: item.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "0A0F0D"))
                            }
                        } else {
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedTab == i ? .white : .white.opacity(0.35))
                                .frame(height: 36)
                        }
                        Text(item.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                i == 0
                                    ? Color(hex: "0EB060")
                                    : (selectedTab == i ? .white : .white.opacity(0.3))
                            )
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 30)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(hex: "111714"))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.6), radius: 24, y: -6)
        )
        .padding(.horizontal, 16)
    }

    private let tabItems: [(icon: String, label: String)] = [
        ("house.fill",     "HOME"),
        ("book.fill",      "LESSONS"),
        ("safari",         "DISCOVERY"),
        ("chart.bar.fill", "RANK"),
        ("gearshape.fill", "SETTINGS"),
    ]
}

// MARK: - StatCard
private struct StatCard: View {
    let stat: StatItem

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(stat.isHighlighted ? .white : .white.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(stat.isHighlighted
                              ? Color(hex: "0EB060").opacity(0.18)
                              : Color.white.opacity(0.07))
                )

            Text(stat.label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.35))
                .tracking(0.8)

            Text(stat.value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            stat.isHighlighted
                                ? Color(hex: "0EB060").opacity(0.55)
                                : Color.white.opacity(0.08),
                            lineWidth: stat.isHighlighted ? 1.5 : 0.5
                        )
                )
        )
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

            // Decorative watermark
            Image(systemName: "brain.head.profile")
                .font(.system(size: 120))
                .foregroundColor(.white.opacity(0.07))
                .offset(x: 130, y: -8)

            VStack(alignment: .leading, spacing: 0) {
                // Tag
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

// MARK: - LessonCard
private struct LessonCard: View {
    let lesson: Lesson

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

            // Progress bar
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
