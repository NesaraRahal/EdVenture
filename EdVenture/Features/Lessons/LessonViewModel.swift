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
            let snapshot = try await db
                .collection("lessons")
                .order(by: "order")
                .getDocuments()

            lessons = snapshot.documents.compactMap { doc in
                LessonModel(id: doc.documentID, data: doc.data())
            }
        } catch {
            errorMessage = error.localizedDescription
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
}
