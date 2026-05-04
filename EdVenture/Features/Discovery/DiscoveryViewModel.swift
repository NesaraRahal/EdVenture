import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

// MARK: - Discovery State

enum DiscoveryState {
    case idle
    case scanning
    case processingImage
    case extractingText
    case generatingContent
    case displayingContent
    case error(String)
}

// MARK: - Discovery ViewModel

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var state: DiscoveryState = .idle
    @Published var scannedImage: UIImage?
    @Published var extractedText: String = ""
    @Published var educationalContent: EducationalContent?
    @Published var isShowingCamera = false
    @Published var isShowingAROverlay = false
    @Published var isShowingDiscoveryQuiz = false
    @Published var isShowingDiscoverySummary = false
    @Published var isShowingDiscoveryReview = false
    @Published var errorMessage: String?
    @Published var scanHistory: [EducationalContent] = []
    @Published var progress: Float = 0.0
    @Published var lastDiscoveryXP: Int = 0
    @Published var discoverySummary: DiscoveryQuizSummaryPayload?
    @Published var discoveryReviewItems: [DiscoveryReviewItem] = []
    
    private let visionRecognizer = VisionTextRecognizer.shared
    private let geminiService = GeminiAPIService.shared
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    
    init() {
        loadScanHistory()
    }
    
    // MARK: - Camera & Capture
    
    func openCamera() {
        state = .scanning
        isShowingCamera = true
    }
    
    func closeCamera() {
        isShowingCamera = false
        if case .scanning = state {
            state = .idle
        }
    }

    func handleCameraError(_ error: Error) {
        isShowingCamera = false
        handleError(error)
    }
    
    /// Handle image captured from camera
    func handleImageCapture(_ image: UIImage) {
        scannedImage = image
        isShowingCamera = false
        processImage(image)
    }
    
    /// Process a local image file
    func processLocalImage(_ image: UIImage) {
        scannedImage = image
        processImage(image)
    }
    
    // MARK: - Text Recognition
    
    private func processImage(_ image: UIImage) {
        Task {
            await extractTextFromImage(image)
        }
    }
    
    private func extractTextFromImage(_ image: UIImage) async {
        state = .extractingText
        progress = 0.2
        
        do {
            let result = try await visionRecognizer.recognizeText(from: image)
            
            extractedText = result.extractedText
            progress = 0.5
            
            // Log barcode detection if any
            if !result.barcodes.isEmpty {
                print("📊 Detected barcodes: \(result.barcodes.map { $0.value }.joined(separator: ", "))")
                
                // If ISBN/barcode detected, prepend to text for better context
                let barcodeInfo = result.barcodes.map { "ISBN/Barcode: \($0.value) (\($0.format))" }.joined(separator: " | ")
                extractedText = barcodeInfo + "\n" + extractedText
            }
            
            print("✅ Text extraction complete")
            print("Detected languages: \(result.detectedLanguages)")
            print("Confidence: \(String(format: "%.0f%%", result.confidence * 100))")
            
            await generateEducationalContent()
            
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - AI Content Generation
    
    private func generateEducationalContent() async {
        state = .generatingContent
        progress = 0.6
        
        do {
            let content = try await geminiService.generateEducationalContent(from: extractedText)
            
            educationalContent = content
            progress = 0.9
            
            // Save to history
            saveScanToHistory(content)
            
            progress = 1.0
            state = .displayingContent
            isShowingAROverlay = true
            
            print("🎓 Educational content generated successfully")
            
        } catch {
            if let geminiError = error as? GeminiError {
                let fallback = makeFallbackContent(from: extractedText, reason: geminiError)
                educationalContent = fallback
                progress = 1.0
                state = .displayingContent
                isShowingAROverlay = true
                saveScanToHistory(fallback)
                return
            }
            handleError(error)
        }
    }
    
    // MARK: - AR Overlay
    
    func showAROverlay() {
        guard educationalContent != nil else {
            errorMessage = "No educational content available"
            return
        }
        isShowingAROverlay = true
    }
    
    func dismissAROverlay() {
        isShowingAROverlay = false
    }
    
    // MARK: - Quiz
    
    func getFirstQuizQuestion() -> EVDiscoveryQuizQuestion? {
        return educationalContent?.quizQuestions.first
    }

    func startDiscoveryQuiz() {
        guard let content = educationalContent, !content.quizQuestions.isEmpty else {
            errorMessage = "No quiz questions are available yet."
            return
        }
        isShowingDiscoveryQuiz = true
    }

    func completeDiscoveryQuiz(correctCount: Int, totalCount: Int) async {
        guard let user = Auth.auth().currentUser else { return }
        guard let content = educationalContent else { return }

        let safeTotal = max(totalCount, 1)
        let safeCorrect = max(min(correctCount, safeTotal), 0)
        let fingerprint = scanFingerprint(for: content)
        let scanRef = db.collection("users").document(user.uid)
            .collection("discoveryScans").document(fingerprint)

        let alreadyAwarded = await isScanAlreadyAwarded(scanRef: scanRef)
        let xpEarned = alreadyAwarded ? 0 : safeCorrect * 10
        lastDiscoveryXP = xpEarned

        await saveDiscoveryQuestions(content: content)

        if !alreadyAwarded {
            do {
                try await scanRef.setData([
                    "title": content.title,
                    "category": content.category,
                    "xpAwarded": true,
                    "correctCount": safeCorrect,
                    "totalCount": safeTotal,
                    "firstScannedAt": Timestamp(date: Date()),
                    "lastScannedAt": Timestamp(date: Date())
                ], merge: true)
            } catch {
                print("Failed to persist discovery scan: \(error.localizedDescription)")
            }
        } else {
            do {
                try await scanRef.setData([
                    "lastScannedAt": Timestamp(date: Date())
                ], merge: true)
            } catch {
                print("Failed to update discovery scan timestamp: \(error.localizedDescription)")
            }
        }

        if xpEarned > 0 {
            let userRef = db.collection("users").document(user.uid)
            do {
                try await userRef.setData([
                    "totalXP": FieldValue.increment(Int64(xpEarned)),
                    "quizXP": FieldValue.increment(Int64(xpEarned)),
                    "updatedAt": Timestamp(date: Date())
                ], merge: true)
            } catch {
                // Best-effort XP update.
                print("Failed to award discovery XP: \(error.localizedDescription)")
            }
        }

        discoverySummary = DiscoveryQuizSummaryPayload(
            title: content.title,
            category: content.category,
            correctCount: safeCorrect,
            totalCount: safeTotal,
            xpEarned: xpEarned,
            isRepeatScan: alreadyAwarded
        )
    }
    
    // MARK: - History Management
    
    private func loadScanHistory() {
        // TODO: Load from persistent storage (Core Data or UserDefaults)
        // For now, keep in-memory
    }
    
    private func saveScanToHistory(_ content: EducationalContent) {
        scanHistory.insert(content, at: 0)
        
        // Keep only last 50 scans
        if scanHistory.count > 50 {
            scanHistory.removeLast()
        }
        
        // TODO: Persist to Core Data or UserDefaults
    }

    private func saveDiscoveryQuestions(content: EducationalContent) async {
        let category = content.category
        guard !category.isEmpty else { return }

        let lessonRef = db.collection("lessons").document(category)
        do {
            let snapshot = try await lessonRef.getDocument()
            if !snapshot.exists {
                try await lessonRef.setData([
                    "title": category.replacingOccurrences(of: "_", with: " ").capitalized,
                    "description": "Auto-generated questions from Discovery Mode scans.",
                    "icon": "sparkles",
                    "color": "38BDF8",
                    "xpReward": 12,
                    "scholars": 0,
                    "totalLevels": 10,
                    "order": 99
                ], merge: true)
            }
        } catch {
            print("Failed to seed lesson document: \(error.localizedDescription)")
        }

        let questionsRef = lessonRef.collection("questions")
        let scanId = content.id
        let now = Date()

        for (index, q) in content.quizQuestions.enumerated() {
            let difficultyScore = difficultyScoreFor(content.difficultyLevel, offset: index)
            let level = min(max(1, (difficultyScore + 9) / 10), 10)
            let order = index + 1
            let questionId = "\(category)_DISC_\(scanId)_Q\(String(format: "%02d", order))"

            let payload: [String: Any] = [
                "lessonId": category,
                "level": level,
                "order": order,
                "difficulty": difficultyScore,
                "xpMin": max(8, difficultyScore / 6),
                "xpMax": max(12, difficultyScore / 4),
                "xpSuggested": max(10, difficultyScore / 5),
                "prompt": q.question,
                "choices": q.options,
                "correctIndex": q.correctAnswerIndex,
                "explanation": q.explanation,
                "tags": content.keyLearningPoints,
                "isActive": true,
                "source": "discovery",
                "sourceScanId": scanId,
                "generatedAt": Timestamp(date: now)
            ]

            do {
                try await questionsRef.document(questionId).setData(payload, merge: true)
            } catch {
                print("Failed to save discovery question: \(error.localizedDescription)")
            }
        }
    }

    private func scanFingerprint(for content: EducationalContent) -> String {
        let normalized = content.extractedText
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let data = Data(normalized.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isScanAlreadyAwarded(scanRef: DocumentReference) async -> Bool {
        do {
            let snapshot = try await scanRef.getDocument()
            let data = snapshot.data() ?? [:]
            return (data["xpAwarded"] as? Bool) ?? false
        } catch {
            return false
        }
    }

    private func difficultyScoreFor(_ level: String, offset: Int) -> Int {
        let base: Int
        switch level.lowercased() {
        case "advanced":
            base = 75
        case "intermediate":
            base = 50
        default:
            base = 25
        }
        return min(95, base + offset * 4)
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        let message: String
        
        if let visionError = error as? VisionError {
            message = visionError.localizedDescription ?? "Vision processing failed"
        } else if let geminiError = error as? GeminiError {
            message = geminiError.localizedDescription ?? "AI generation failed"
        } else {
            message = error.localizedDescription
        }
        
        state = .error(message)
        errorMessage = message
        
        print("❌ Error: \(message)")
    }
    
    func clearError() {
        errorMessage = nil
        if case .error = state {
            state = .idle
        }
    }
    
    func reset() {
        state = .idle
        scannedImage = nil
        extractedText = ""
        educationalContent = nil
        errorMessage = nil
        progress = 0.0
    }
    
    // MARK: - API Configuration
    
    func setGeminiAPIKey(_ key: String) {
        geminiService.setAPIKey(key)
    }

    private func makeFallbackContent(from text: String, reason: GeminiError? = nil) -> EducationalContent {
        let lines = text
            .split(whereSeparator: { $0.isNewline })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let title = lines.first ?? "Detected Text Object"
        let summarySeed = lines.prefix(3).joined(separator: " ")
        let reasonText: String = {
            guard let reason else {
                return "AI service is currently unavailable."
            }
            switch reason {
            case .missingAPIKey:
                return "Gemini API key is missing."
            case .apiError(let status):
                return "Gemini service returned HTTP \(status)."
            case .invalidResponse:
                return "Gemini returned an invalid response."
            case .invalidJSON:
                return "Gemini response format was invalid."
            case .networkError:
                return "Network error while contacting Gemini."
            }
        }()
        let summary = summarySeed.isEmpty
            ? "Text detected successfully. \(reasonText)"
            : "Detected text: \(summarySeed.prefix(220)). \(reasonText)"

        return EducationalContent(
            id: UUID().uuidString,
            title: title,
            detectedObjectName: "Scanned Text",
            category: "computer_science",
            shortSummary: summary,
            educationalFacts: [
                "OCR extraction completed successfully",
                "Use clearer lighting for better accuracy",
                "You can scan from camera or choose from gallery",
                reasonText
            ],
            difficultyLevel: "Beginner",
            keyLearningPoints: [
                "Text recognition",
                "Keyword extraction",
                "AI enrichment (requires API key)"
            ],
            quizQuestions: [
                EVDiscoveryQuizQuestion(
                    id: UUID().uuidString,
                    question: "What improves OCR quality the most?",
                    options: ["Better lighting", "Lower resolution", "Tilted camera", "More zoom blur"],
                    correctAnswerIndex: 0,
                    explanation: "Clear lighting and focus significantly improve OCR accuracy."
                )
            ],
            arOverlayCaption: "Text detected. Add API key for full AI content.",
            extractedText: text,
            generatedAt: Date()
        )
    }
}

struct DiscoveryQuizSummaryPayload {
    let title: String
    let category: String
    let correctCount: Int
    let totalCount: Int
    let xpEarned: Int
    let isRepeatScan: Bool
}

struct DiscoveryReviewItem: Identifiable {
    let id: String
    let order: Int
    let question: String
    let options: [String]
    let selectedIndex: Int
    let correctIndex: Int
    let explanation: String

    var isCorrect: Bool {
        selectedIndex == correctIndex
    }
}
