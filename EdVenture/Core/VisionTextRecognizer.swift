import Foundation
import Vision
import CoreImage
import UIKit

// MARK: - Vision Text Recognizer
// Uses Apple Vision framework for OCR and barcode detection

struct VisionTextRecognitionResult {
    let extractedText: String
    let barcodes: [BarcodeInfo]
    let detectedLanguages: [String]
    let confidence: Float
}

struct BarcodeInfo {
    let value: String
    let format: String
    let confidence: Float
}

@MainActor
class VisionTextRecognizer {
    static let shared = VisionTextRecognizer()
    
    private init() {}
    
    /// Recognize text from an image using Vision framework
    /// - Parameter image: UIImage to perform OCR on
    /// - Returns: Extracted text, barcodes, and metadata
    func recognizeText(from image: UIImage) async throws -> VisionTextRecognitionResult {
        guard let cgImage = makeCGImage(from: image) else {
            throw VisionError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        // First pass: accurate OCR with language hints
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["en-US", "en-GB"]
        textRequest.usesLanguageCorrection = true
        
        // Barcode detection request
        let barcodeRequest = VNDetectBarcodesRequest()
        barcodeRequest.symbologies = [
            .EAN8, .EAN13, .upce, .code128, .code39,
            .qr, .dataMatrix, .pdf417, .aztec
        ]
        
        var recognizedTexts: [String] = []
        var textConfidences: [Float] = []
        var detectedBarcodes: [BarcodeInfo] = []
        var languages: Set<String> = []
        var textObservations: [VNRecognizedTextObservation] = []

        // Process text recognition with fallback
        do {
            try requestHandler.perform([textRequest])
            textObservations = textRequest.results ?? []
        } catch {
            // Fallback pass for devices/simulator states where accurate OCR model cannot initialize
            let fallbackTextRequest = VNRecognizeTextRequest()
            fallbackTextRequest.recognitionLevel = .fast
            fallbackTextRequest.usesLanguageCorrection = false

            do {
                try requestHandler.perform([fallbackTextRequest])
                textObservations = fallbackTextRequest.results ?? []
            } catch {
                throw VisionError.processingError(error)
            }
        }

        for observation in textObservations {
            // Get top candidate text
            if let candidate = observation.topCandidates(1).first {
                recognizedTexts.append(candidate.string)
                textConfidences.append(Float(observation.confidence))

                // Attempt to detect language from text
                let detectedLanguage = detectLanguage(from: candidate.string)
                if let lang = detectedLanguage {
                    languages.insert(lang)
                }
            }
        }
        
        // Process barcode detection (non-fatal)
        do {
            try requestHandler.perform([barcodeRequest])

            if let results = barcodeRequest.results as? [VNBarcodeObservation] {
                for observation in results {
                    if let payloadStringValue = observation.payloadStringValue {
                        let format = observation.symbology.rawValue
                        let barcode = BarcodeInfo(
                            value: payloadStringValue,
                            format: format,
                            confidence: Float(observation.confidence)
                        )
                        detectedBarcodes.append(barcode)

                        // If barcode is ISBN, try to recognize it as text
                        if format.contains("EAN") || format.contains("UPC") {
                            recognizedTexts.append("ISBN: \(payloadStringValue)")
                        }
                    }
                }
            }
        } catch {
            // Ignore barcode errors; OCR result may still be valid
        }
        
        let combinedText = recognizedTexts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        let averageConfidence = textConfidences.isEmpty ? 0 : textConfidences.reduce(0, +) / Float(textConfidences.count)
        
        guard !combinedText.isEmpty else {
            throw VisionError.noTextDetected
        }
        
        return VisionTextRecognitionResult(
            extractedText: combinedText,
            barcodes: detectedBarcodes,
            detectedLanguages: Array(languages),
            confidence: averageConfidence
        )
    }
    
    /// Recognize text from image data (e.g., from camera buffer)
    /// - Parameter pixelBuffer: CMSampleBuffer pixel buffer from camera
    /// - Returns: Extracted text and metadata
    func recognizeText(from pixelBuffer: CVPixelBuffer) async throws -> VisionTextRecognitionResult {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw VisionError.invalidImage
        }
        
        let image = UIImage(cgImage: cgImage)
        return try await recognizeText(from: image)
    }
    
    // MARK: - Private Helpers
    
    private func detectLanguage(from text: String) -> String? {
        // Simple language detection based on character ranges
        // This is a placeholder - for production, use NLLanguageRecognizer
        
        let englishPattern = "[a-zA-Z0-9\\s\\p{P}]+"
        let regex = try? NSRegularExpression(pattern: englishPattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        
        if let matches = regex?.matches(in: text, options: [], range: range),
           matches.count > 0 {
            return "en"
        }
        
        return nil
    }

    private func makeCGImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage {
            return cgImage
        }

        if let ciImage = image.ciImage {
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }

        if let data = image.jpegData(compressionQuality: 1.0),
           let temp = UIImage(data: data),
           let cgImage = temp.cgImage {
            return cgImage
        }

        return nil
    }
}

// MARK: - Error Handling

enum VisionError: LocalizedError {
    case invalidImage
    case noTextDetected
    case noBarcodesDetected
    case processingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided to Vision framework"
        case .noTextDetected:
            return "No readable text detected in the image"
        case .noBarcodesDetected:
            return "No barcodes detected in the image"
        case .processingError(let error):
            let message = error.localizedDescription
            if message.localizedCaseInsensitiveContains("inference context") {
                return "Text model initialization failed. Try a clearer image, then retry. If using Simulator, prefer Gallery and test on a real device for best OCR support."
            }
            return "Vision processing error: \(message)"
        }
    }
}
