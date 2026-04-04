//
//  LessonViewModel.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-04-02.
//

import SwiftUI
import FirebaseFirestore
import Combine

// MARK: - LessonsViewModel
// Features/Lessons/LessonsViewModel.swift

@MainActor
final class LessonsViewModel: ObservableObject {

    @Published var lessons:        [LessonModel] = []
    @Published var isLoading:      Bool          = true
    @Published var errorMessage:   String?       = nil
    @Published var searchText:     String        = ""
    @Published var selectedFilter: String        = "All"

    private let db = Firestore.firestore()

    // All filter chips — "All" + each lesson title
    var filterChips: [String] {
        ["All"] + lessons.map { $0.title }
    }

    // Lessons after search + filter applied
    var filteredLessons: [LessonModel] {
        var result = lessons

        // Filter chip
        if selectedFilter != "All" {
            result = result.filter { $0.title == selectedFilter }
        }

        // Search text
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    // MARK: - Fetch from Firestore
    func fetchLessons() async {
        isLoading    = true
        errorMessage = nil

        do {
            // Upsert the default catalog each load so missing/partial documents are repaired.
            try await seedDefaultLessons()

            let snapshot = try await db.collection("lessons").getDocuments()

            let parsed = snapshot.documents.compactMap { doc in
                LessonModel(id: doc.documentID, data: doc.data())
            }

            lessons = parsed.sorted { $0.order < $1.order }

            if lessons.isEmpty {
                lessons = localFallbackLessons().sorted { $0.order < $1.order }
            }

            if !filterChips.contains(selectedFilter) {
                selectedFilter = "All"
            }
        } catch {
            errorMessage = error.localizedDescription
            lessons = localFallbackLessons().sorted { $0.order < $1.order }
            selectedFilter = "All"
        }

        isLoading = false
    }

    // MARK: - Add lesson to user's practice list
    // Stores the lesson ID under the current user's profile in Firestore
    func addToPractice(lessonId: String, userId: String) async {
        let ref = db.collection("users").document(userId)
            .collection("activeLessons").document(lessonId)
        do {
            try await ref.setData([
                "lessonId":  lessonId,
                "addedAt":   Timestamp(date: Date()),
                "progress":  0.0
            ], merge: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Default lesson catalog seed
    // Seeds lesson metadata only (cards/progression config), not question bank.
    private func seedDefaultLessons() async throws {
        for lesson in defaultLessonPayloads() {
            try await db.collection("lessons").document(lesson.id).setData(lesson.data, merge: true)
        }
    }

    private func localFallbackLessons() -> [LessonModel] {
        defaultLessonPayloads().compactMap { payload in
            LessonModel(id: payload.id, data: payload.data)
        }
    }

    private func defaultLessonPayloads() -> [(id: String, data: [String: Any])] {
        [
            (
                id: "astronomy",
                data: [
                    "title": "Astronomy",
                    "description": "Master the cosmos through stellar evolution, deep-space objects, and celestial mechanics.",
                    "icon": "rocket.fill",
                    "color": "0EB060",
                    "xpReward": 50,
                    "scholars": 120,
                    "totalLevels": 10,
                    "questionsPerLevel": 10,
                    "timeRangeSeconds": [60, 180],
                    "difficultyModel": "adaptive-linear",
                    "order": 1
                ]
            ),
            (
                id: "computer-science",
                data: [
                    "title": "Computer Science",
                    "description": "Build core understanding of algorithms, systems thinking, and computational problem solving.",
                    "icon": "desktopcomputer",
                    "color": "4FD2FF",
                    "xpReward": 55,
                    "scholars": 135,
                    "totalLevels": 10,
                    "questionsPerLevel": 10,
                    "timeRangeSeconds": [60, 180],
                    "difficultyModel": "adaptive-linear",
                    "order": 2
                ]
            ),
            (
                id: "philosophy",
                data: [
                    "title": "Philosophy",
                    "description": "Explore logic, ethics, and major schools of thought through concise reasoning challenges.",
                    "icon": "brain.head.profile",
                    "color": "75DFFF",
                    "xpReward": 50,
                    "scholars": 128,
                    "totalLevels": 10,
                    "questionsPerLevel": 10,
                    "timeRangeSeconds": [60, 180],
                    "difficultyModel": "adaptive-linear",
                    "order": 3
                ]
            ),
            (
                id: "mathematics",
                data: [
                    "title": "Mathematics",
                    "description": "Strengthen number sense, algebra, and quantitative logic with progressive timed MCQs.",
                    "icon": "sum",
                    "color": "F9C74F",
                    "xpReward": 60,
                    "scholars": 142,
                    "totalLevels": 10,
                    "questionsPerLevel": 10,
                    "timeRangeSeconds": [60, 180],
                    "difficultyModel": "adaptive-linear",
                    "order": 4
                ]
            ),
            (
                id: "biology",
                data: [
                    "title": "Biology",
                    "description": "Understand life systems from cells to ecosystems with escalating difficulty levels.",
                    "icon": "leaf.fill",
                    "color": "7EF5A8",
                    "xpReward": 52,
                    "scholars": 126,
                    "totalLevels": 10,
                    "questionsPerLevel": 10,
                    "timeRangeSeconds": [60, 180],
                    "difficultyModel": "adaptive-linear",
                    "order": 5
                ]
            )
        ]
    }
}
