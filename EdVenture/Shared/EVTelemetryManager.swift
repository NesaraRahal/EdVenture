import Foundation
import FirebaseAuth
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebaseFirestore

enum EVTelemetryMode: String, CaseIterable, Identifiable {
    case importantOnly = "important_only"
    case businessValue = "business_value"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .importantOnly:
            return "Important Logs Only"
        case .businessValue:
            return "Important + Business"
        }
    }

    var detail: String {
        switch self {
        case .importantOnly:
            return "Collect crash, auth, and critical flow events only."
        case .businessValue:
            return "Also collect anonymized product usage insights with business value."
        }
    }
}

enum EVTelemetryEventLevel: String {
    case important
    case business
}

struct EVTelemetryPreferences {
    let mode: EVTelemetryMode
    let consentPromptAnswered: Bool
}

enum EVTelemetryManager {
    private static let db = Firestore.firestore()

    static func loadPreferences(for uid: String) async throws -> EVTelemetryPreferences {
        let doc = try await db
            .collection("users")
            .document(uid)
            .collection("preferences")
            .document("telemetry")
            .getDocument()

        let data = doc.data() ?? [:]
        let modeRaw = data["telemetryMode"] as? String
        let explicitBusinessEnabled = data["businessTelemetryEnabled"] as? Bool

        let resolvedModeRaw: String
        if let modeRaw {
            resolvedModeRaw = modeRaw
        } else if explicitBusinessEnabled == true {
            resolvedModeRaw = EVTelemetryMode.businessValue.rawValue
        } else {
            resolvedModeRaw = EVTelemetryMode.importantOnly.rawValue
        }

        let mode = EVTelemetryMode(rawValue: resolvedModeRaw) ?? .importantOnly
        let consentPromptAnswered = data["consentPromptAnswered"] as? Bool ?? false

        return EVTelemetryPreferences(
            mode: mode,
            consentPromptAnswered: consentPromptAnswered
        )
    }

    static func savePreferences(for uid: String,
                                mode: EVTelemetryMode,
                                source: String = "settings_screen") async throws {
        let now = Date()
        let userRef = db.collection("users").document(uid)
        let preferenceRef = userRef.collection("preferences").document("telemetry")

        let batch = db.batch()
        batch.setData([
            "telemetryMode": mode.rawValue,
            "businessTelemetryEnabled": mode == .businessValue,
            "consentPromptAnswered": true,
            "updatedAt": Timestamp(date: now),
            "updatedSource": source
        ], forDocument: preferenceRef, merge: true)

        batch.setData([
            "telemetryConsentPending": false,
            "updatedAt": Timestamp(date: now)
        ], forDocument: userRef, merge: true)

        try await batch.commit()

        Analytics.setUserProperty(mode == .businessValue ? "true" : "false",
                                  forName: "business_telemetry_enabled")
        Crashlytics.crashlytics().setCustomValue(mode.rawValue, forKey: "telemetry_mode")
        Crashlytics.crashlytics().setCustomValue(mode == .businessValue, forKey: "business_telemetry_enabled")
    }

    static func shouldPresentConsentPrompt(for uid: String) async throws -> Bool {
        let userDoc = try await db.collection("users").document(uid).getDocument()
        let isPending = userDoc.data()?["telemetryConsentPending"] as? Bool ?? false
        guard isPending else { return false }

        let preferences = try await loadPreferences(for: uid)
        return !preferences.consentPromptAnswered
    }

    static func collectImportant(event: String,
                                 metadata: [String: String] = [:]) async {
        await writeEvent(
            uid: Auth.auth().currentUser?.uid,
            event: event,
            level: .important,
            metadata: metadata
        )
    }

    static func collectBusiness(event: String,
                                metadata: [String: String] = [:]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let preferences = try await loadPreferences(for: uid)
            guard preferences.consentPromptAnswered,
                  preferences.mode == .businessValue
            else {
                return
            }

            await writeEvent(
                uid: uid,
                event: event,
                level: .business,
                metadata: metadata
            )
        } catch {
            // Swallow telemetry failures to avoid blocking app flows.
        }
    }

    private static func writeEvent(uid: String?,
                                   event: String,
                                   level: EVTelemetryEventLevel,
                                   metadata: [String: String] = [:]) async {
        do {
            let now = Date()
            var payload: [String: Any] = [
                "event": event,
                "level": level.rawValue,
                "source": "ios_app",
                "createdAt": Timestamp(date: now)
            ]

            if let uid {
                payload["uid"] = uid
            }

            if !metadata.isEmpty {
                payload["metadata"] = metadata
            }

            // Firebase Analytics integration for aggregate analytics dashboards.
            var analyticsPayload: [String: Any] = [
                "telemetry_level": level.rawValue,
                "telemetry_source": "ios_app"
            ]
            for (key, value) in metadata {
                analyticsPayload["m_\(sanitizeAnalyticsKey(key))"] = value
            }
            Analytics.logEvent(
                sanitizeAnalyticsEventName(event),
                parameters: analyticsPayload
            )

            // Crashlytics breadcrumb-style logging for operational diagnostics.
            let crashlytics = Crashlytics.crashlytics()
            crashlytics.log("telemetry event=\(event) level=\(level.rawValue)")
            crashlytics.setCustomValue(level.rawValue, forKey: "last_telemetry_level")
            crashlytics.setCustomValue(event, forKey: "last_telemetry_event")
            if let uid {
                crashlytics.setUserID(uid)
            }

            // Only mirror important events to Firestore realtime logs.
            guard let uid, shouldMirrorToFirestore(level: level) else {
                return
            }

            let telemetryRootRef = db.collection("telemetryEvents").document(uid)
            let eventRef = telemetryRootRef.collection("events").document()

            // Realtime monitoring stream (can be watched live via Firestore listeners).
            let realtimeRootRef = db.collection("telemetryRealtime").document(uid)
            let realtimeStreamRef = realtimeRootRef.collection("stream").document()

            let batch = db.batch()
            batch.setData([
                "uid": uid,
                "lastEvent": event,
                "lastLevel": level.rawValue,
                "lastSource": "ios_app",
                "lastMetadata": metadata,
                "lastEventAt": Timestamp(date: now),
                "totalEvents": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: now)
            ], forDocument: telemetryRootRef, merge: true)

            batch.setData(payload, forDocument: eventRef, merge: false)

            batch.setData([
                "uid": uid,
                "lastEvent": event,
                "lastLevel": level.rawValue,
                "lastSource": "ios_app",
                "updatedAt": Timestamp(date: now)
            ], forDocument: realtimeRootRef, merge: true)

            batch.setData(payload, forDocument: realtimeStreamRef, merge: false)
            try await batch.commit()
        } catch {
            // Swallow telemetry failures to avoid blocking app flows.
        }
    }

    private static func shouldMirrorToFirestore(level: EVTelemetryEventLevel) -> Bool {
        level == .important
    }

    private static func sanitizeAnalyticsEventName(_ raw: String) -> String {
        let lower = raw.lowercased()
        let cleaned = lower.map { char -> Character in
            if char.isLetter || char.isNumber || char == "_" {
                return char
            }
            return "_"
        }
        let joined = String(cleaned)
        let prefixed = joined.first?.isNumber == true ? "ev_\(joined)" : joined
        let fallback = prefixed.isEmpty ? "ev_telemetry_event" : prefixed
        return String(fallback.prefix(40))
    }

    private static func sanitizeAnalyticsKey(_ raw: String) -> String {
        let lower = raw.lowercased()
        let cleaned = lower.map { char -> Character in
            if char.isLetter || char.isNumber || char == "_" {
                return char
            }
            return "_"
        }
        return String(cleaned.prefix(24))
    }
}
