import SwiftUI
import Combine

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
    @Published var errorMessage: String?
    @Published var scanHistory: [EducationalContent] = []
    @Published var progress: Float = 0.0
    
    private let visionRecognizer = VisionTextRecognizer.shared
    private let geminiService = GeminiAPIService.shared
    
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
            
            print("🎓 Educational content generated successfully")
            
        } catch {
            if let geminiError = error as? GeminiError {
                let fallback = makeFallbackContent(from: extractedText, reason: geminiError)
                educationalContent = fallback
                progress = 1.0
                state = .displayingContent
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
