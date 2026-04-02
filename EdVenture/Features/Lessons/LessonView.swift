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

    var onSettings: (() -> Void)?
    var onHome:     (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "0A0F0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Liquid glass nav ──────────────────────────────────
                navBar

                // ── Page title ────────────────────────────────────────
                HStack {
                    Text("Lessons")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)

                // ── Search bar ────────────────────────────────────────
                searchBar
                    .padding(.horizontal, 20)
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
                Button {} label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
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
        .padding(.vertical, 12)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color(hex: "0A0F0D").opacity(0.6))
                VStack {
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5)
                }
            }
        )
        .padding(.top, 44)
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
        .frame(height: 46)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
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
                                    : .white.opacity(0.6)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        vm.selectedFilter == chip
                                            ? Color(hex: "0EB060")
                                            : Color.white.opacity(0.08)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        vm.selectedFilter == chip
                                            ? Color.clear
                                            : Color.white.opacity(0.1),
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
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.offset) { i, item in
                Button {
                    if i == 0 { onHome?() }
                    if i == 4 { onSettings?() }
                } label: {
                    VStack(spacing: 4) {
                        if i == 1 {
                            // Lessons tab — active pill
                            ZStack {
                                Capsule()
                                    .fill(Color(hex: "0EB060"))
                                    .frame(width: 52, height: 32)
                                Image(systemName: item.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "0A0F0D"))
                            }
                        } else {
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.3))
                                .frame(height: 32)
                        }
                        Text(item.label)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(i == 1 ? Color(hex: "0EB060") : .white.opacity(0.28))
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous).fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color(hex: "111714").opacity(0.75))
                RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            }
        )
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.5), radius: 20, y: -4)
    }

    private let tabItems: [(icon: String, label: String)] = [
        ("house.fill",     "HOME"),
        ("book.fill",      "LESSONS"),
        ("safari",         "DISCOVERY"),
        ("chart.bar.fill", "RANK"),
        ("gearshape.fill", "SETTINGS"),
    ]

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
                .font(.system(size: 26, weight: .bold, design: .rounded))
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
                        .foregroundColor(.white.opacity(0.35))
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
                .frame(height: 50)
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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    LessonsView()
}
