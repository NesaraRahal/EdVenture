//
//  LessonView.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-04-02.
//

import SwiftUI
import FirebaseAuth

// MARK: - LessonsView
// Features/Lessons/LessonsView.swift

struct LessonsView: View {

    @StateObject private var vm      = LessonsViewModel()
    @State private var appeared      = false
    @State private var addedLessons  = Set<String>()   // tracks "Add to Practice" taps locally

    var onHome:      (() -> Void)?
    var onDiscovery: (() -> Void)?
    var onRank:      (() -> Void)?
    var onSettings:  (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Liquid glass nav ──────────────────────────────────
                navBar

                // ── Search bar ────────────────────────────────────────
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                // ── Filter chips ──────────────────────────────────────
                filterChips
                    .padding(.bottom, 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                // ── Content ───────────────────────────────────────────
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "0EB060"))
                        .scaleEffect(1.2)
                    Spacer()
                } else if let error = vm.errorMessage {
                    Spacer()
                    Text(error)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                } else if vm.filteredLessons.isEmpty {
                    Spacer()
                    Text("No lessons found.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                    Spacer()
                } else {
                    // ── Lesson cards ──────────────────────────────────
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(Array(vm.filteredLessons.enumerated()), id: \.element.id) { i, lesson in
                                LessonCard(
                                    lesson:   lesson,
                                    isAdded:  addedLessons.contains(lesson.id)
                                ) {
                                    handleAddToPractice(lesson: lesson)
                                }
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.45).delay(0.2 + Double(i) * 0.07),
                                    value: appeared
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 110)
                    }
                }
            }

            // ── Tab bar ───────────────────────────────────────────────
            tabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            appeared = true
            Task { await vm.fetchLessons() }
        }
    }

    // MARK: - Nav bar
    private var navBar: some View {
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
            HStack(spacing: 10) {
                EVLiquidGlassIconButton(systemName: "bell.fill") {}

                Button { onSettings?() } label: {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 52)
    }

    // MARK: - Search bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.35))
            ZStack(alignment: .leading) {
                if vm.searchText.isEmpty {
                    Text("Search a Lesson")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                }
                TextField("", text: $vm.searchText)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white)
                    .tint(Color(hex: "0EB060"))
                    .autocorrectionDisabled()
            }
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Filter chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.filterChips, id: \.self) { chip in
                    Button {
                        vm.selectedFilter = chip
                    } label: {
                        Text(chip)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(
                                vm.selectedFilter == chip
                                    ? Color(hex: "0A0F0D")
                                    : .white.opacity(0.78)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        vm.selectedFilter == chip
                                            ? Color(hex: "0EB060")
                                            : Color.white
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        vm.selectedFilter == chip
                                            ? Color.clear
                                            : Color.white.opacity(0.12),
                                        lineWidth: 0.5
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .animation(.easeInOut(duration: 0.18), value: vm.selectedFilter)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Tab bar
    private var tabBar: some View {
        EVMainTabBar(activeTab: .lessons) { tab in
            switch tab {
            case .home:
                onHome?()
            case .discovery:
                onDiscovery?()
            case .rank:
                onRank?()
            case .settings:
                onSettings?()
            default:
                break
            }
        }
    }

    // MARK: - Add to practice handler
    private func handleAddToPractice(lesson: LessonModel) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        addedLessons.insert(lesson.id)
        Task { await vm.addToPractice(lessonId: lesson.id, userId: uid) }
    }
}

// MARK: - LessonCard
private struct LessonCard: View {
    let lesson:  LessonModel
    let isAdded: Bool
    let onAdd:   () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Icon ──────────────────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: lesson.color).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: lesson.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color(hex: lesson.color))
            }
            .padding(.bottom, 16)

            // ── Title ─────────────────────────────────────────────────
            Text(lesson.title)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 8)

            // ── Description ───────────────────────────────────────────
            Text(lesson.description)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)

            // ── Meta row ──────────────────────────────────────────────
            HStack(spacing: 16) {
                // XP
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "0EB060"))
                    Text("\(lesson.xpReward) XP / Q")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "0EB060"))
                }
                // Scholars
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                    Text("\(lesson.scholars)+ SCHOLARS")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.bottom, 20)

            // ── Add to Practice button ────────────────────────────────
            Button {
                if !isAdded { onAdd() }
            } label: {
                HStack(spacing: 8) {
                    if isAdded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(isAdded ? "Added to Practice" : "Add to Practice")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(isAdded ? Color(hex: "0EB060") : Color(hex: "0A0F0D"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isAdded
                        ? Color(hex: "0EB060").opacity(0.12)
                        : Color(hex: "0EB060")
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isAdded ? Color(hex: "0EB060").opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .animation(.easeInOut(duration: 0.2), value: isAdded)
            .disabled(isAdded)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.045), Color(hex: "0EB060").opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
                .overlay(alignment: .topTrailing) {
                    Image(systemName: lesson.icon)
                        .font(.system(size: 110, weight: .light))
                        .foregroundColor(Color(hex: lesson.color).opacity(0.08))
                        .padding(.trailing, 24)
                        .padding(.top, 18)
                }
        )
    }
}

#Preview {
    LessonsView()
}
