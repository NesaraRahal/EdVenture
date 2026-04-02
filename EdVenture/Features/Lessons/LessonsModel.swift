//
//  LessonsModel.swift
//  EdVenture
//
//  Created by COBSCCOMP24.2p-053 on 2026-04-02.
//

import SwiftUI
import FirebaseFirestore

// MARK: - LessonModel
// Features/Lessons/LessonModel.swift

struct LessonModel: Identifiable {
    let id: String           // Firestore document ID e.g. "astronomy"
    let title: String
    let description: String
    let icon: String         // SF Symbol name
    let color: String        // hex string for icon bg accent
    let xpReward: Int
    let scholars: Int
    let totalLevels: Int
    let order: Int           // display sort order

    // MARK: - Init from Firestore document
    init?(id: String, data: [String: Any]) {
        guard
            let title       = data["title"]       as? String,
            let description = data["description"] as? String,
            let icon        = data["icon"]        as? String,
            let totalLevels = data["totalLevels"] as? Int,
            let order       = data["order"]       as? Int
        else { return nil }

        self.id          = id
        self.title       = title
        self.description = description
        self.icon        = icon
        self.color       = data["color"]     as? String ?? "0EB060"
        self.xpReward    = data["xpReward"]  as? Int    ?? 50
        self.scholars    = data["scholars"]  as? Int    ?? 0
        self.totalLevels = totalLevels
        self.order       = order
    }
}
