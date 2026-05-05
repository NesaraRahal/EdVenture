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
    @Published var activePracticeLessonIDs: Set<String> = []
    @Published var processingLessonIDs: Set<String> = []

    private let db = Firestore.firestore()

    // All filter chips — "All" + each lesson title
    var filterChips: [String] {
        let titles = lessons
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.isEmpty ? "Untitled" : $0 }

        return ["All"] + Array(NSOrderedSet(array: titles)).compactMap { $0 as? String }
    }

    // Lessons after search + filter applied
    var filteredLessons: [LessonModel] {
        var result = lessons

        // Filter chip
        if selectedFilter != "All" {
            result = result.filter {
                $0.title.trimmingCharacters(in: .whitespacesAndNewlines) == selectedFilter
            }
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
            let snapshot = try await db
                .collection("lessons")
                .order(by: "order")
                .getDocuments()

            var loadedLessons = snapshot.documents.compactMap { doc in
                LessonModel(id: doc.documentID, data: doc.data())
            }

            let missingLessonIds = Self.coreLessonSeeds
                .map { $0.id }
                .filter { id in
                    !loadedLessons.contains(where: { $0.id == id })
                }

            if !missingLessonIds.isEmpty {
                for seed in Self.coreLessonSeeds where missingLessonIds.contains(seed.id) {
                    try await db.collection("lessons").document(seed.id).setData(seed.data, merge: true)
                    if let model = LessonModel(id: seed.id, data: seed.data) {
                        loadedLessons.append(model)
                    }
                }
            }

            lessons = loadedLessons.sorted { $0.order < $1.order }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private static let coreLessonSeeds: [(id: String, data: [String: Any])] = [
        (
            id: "astronomy",
            data: [
                "title": "Astronomy",
                "description": "Explore stars, galaxies, and cosmic phenomena through bite-sized quizzes.",
                "icon": "sparkles",
                "color": "4FC3A1",
                "xpReward": 15,
                "scholars": 120,
                "totalLevels": 10,
                "order": 1
            ]
        ),
        (
            id: "philosophy",
            data: [
                "title": "Philosophy",
                "description": "Reason through ideas, ethics, and arguments in focused challenges.",
                "icon": "brain.head.profile",
                "color": "F59E0B",
                "xpReward": 13,
                "scholars": 128,
                "totalLevels": 10,
                "order": 2
            ]
        ),
        (
            id: "biology",
            data: [
                "title": "Biology",
                "description": "Train on cells, systems, and life science fundamentals.",
                "icon": "leaf.fill",
                "color": "10B981",
                "xpReward": 14,
                "scholars": 110,
                "totalLevels": 10,
                "order": 3
            ]
        ),
        (
            id: "mathematics",
            data: [
                "title": "Mathematics",
                "description": "Sharpen logic, patterns, and calculation speed.",
                "icon": "function",
                "color": "8B5CF6",
                "xpReward": 16,
                "scholars": 140,
                "totalLevels": 10,
                "order": 4
            ]
        ),
        (
            id: "computer_science",
            data: [
                "title": "Computer Science",
                "description": "Build fluency in algorithms, data, and systems.",
                "icon": "cpu",
                "color": "38BDF8",
                "xpReward": 14,
                "scholars": 132,
                "totalLevels": 10,
                "order": 5
            ]
        )
    ]

    // MARK: - Fetch user's active practice lessons
    func fetchActivePracticeLessons(userId: String) async {
        errorMessage = nil

        do {
            let snapshot = try await db
                .collection("users")
                .document(userId)
                .collection("activeLessons")
                .getDocuments()

            activePracticeLessonIDs = Set(snapshot.documents.map { $0.documentID })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Add lesson to user's practice list
    // Stores the lesson ID under the current user's profile in Firestore
    func addToPractice(lessonId: String, userId: String) async {
        guard !activePracticeLessonIDs.contains(lessonId) else { return }
        guard !processingLessonIDs.contains(lessonId) else { return }

        processingLessonIDs.insert(lessonId)
        defer { processingLessonIDs.remove(lessonId) }

        let ref = db.collection("users").document(userId)
            .collection("activeLessons").document(lessonId)
        do {
            try await ref.setData([
                "lessonId":  lessonId,
                "addedAt":   Timestamp(date: Date()),
                "progress":  0.0
            ], merge: true)

            // Frontend state mirrors backend success
            activePracticeLessonIDs.insert(lessonId)

            // Get lesson title for notification
            if let lesson = lessons.first(where: { $0.id == lessonId }) {
                // Add to in-app list and trigger one system notification
                NotificationsStore.shared.addNotification(
                    title: "Lesson Added to Practice",
                    description: "\(lesson.title) is ready to practice",
                    type: .lessonAdded
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
