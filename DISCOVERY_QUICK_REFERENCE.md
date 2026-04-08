# Discovery Mode - Quick Reference

## 📁 File Structure

```
EdVenture/
├── Core/
│   ├── GeminiAPIService.swift          ← AI API integration
│   ├── VisionTextRecognizer.swift      ← OCR + Barcode detection
│   ├── CameraViewController.swift      ← Camera capture UI
│   └── APIConfigurationService.swift   ← Firebase Remote Config setup
│
└── Features/Discovery/
    ├── DiscoveryView.swift             ← Main UI (idle & content views)
    ├── DiscoveryViewModel.swift        ← State management
    ├── AROverlayView.swift             ← AR floating cards
    └── DiscoveryQuizView.swift         ← Quiz questions UI
```

---

## 🔑 Key Classes & Methods

### GeminiAPIService

```swift
// Initialize (automatic via AppDelegate)
GeminiAPIService.shared.setAPIKey(key)

// Generate content
let content = try await geminiService.generateEducationalContent(from: extractedText)
```

### VisionTextRecognizer

```swift
// Recognize text from image
let result = try await recognizer.recognizeText(from: image)
// Returns: extractedText, barcodes[], languages[], confidence

// Recognize from pixel buffer (live camera)
let result = try await recognizer.recognizeText(from: pixelBuffer)
```

### DiscoveryViewModel

```swift
@Published var state: DiscoveryState      // idle, scanning, processing, error
@Published var scannedImage: UIImage?     // Last captured image
@Published var extractedText: String      // OCR result
@Published var educationalContent: EducationalContent?  // AI result

// Methods
func openCamera()                         // Show camera
func handleImageCapture(_ image: UIImage) // Process captured image
func showAROverlay()                      // Display AR view
func reset()                              // Clear all state
```

---

## 🎯 Data Flow

```
User → Camera → CameraViewController
        ↓
    UIImage
        ↓
    DiscoveryViewModel.handleImageCapture()
        ↓
    VisionTextRecognizer.recognizeText()
        ↓
    extractedText + barcodes
        ↓
    GeminiAPIService.generateEducationalContent()
        ↓
    EducationalContent (JSON parsed)
        ↓
    DiscoveryView displays content
        ↓
    User taps "View AR"
        ↓
    AROverlayView shows floating cards
        ↓
    User taps "Take Quiz"
        ↓
    DiscoveryQuizView shows Q&A
```

---

## 🔧 Configuration

### Required in Firebase Remote Config

```
Parameter: gemini_api_key
Type: String
Value: [Your Gemini API Key]
```

### Required in Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>Scan educational materials...</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>For AR positioning...</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
    <string>camera</string>
</array>
```

---

## 🎮 User Flow

1. **Discovery Tab** → "Start Scanning" button
2. **Camera Opens** → Point at object
3. **Capture** → Tap button to capture
4. **Processing** → Shows progress bar
5. **Results** → Display extracted content
6. **View AR** → Show floating cards (optional)
7. **Take Quiz** → Answer questions (optional)
8. **Scan Again** → Repeat

---

## 💻 Example Usage

```swift
// In your view controller
@StateObject private var viewModel = DiscoveryViewModel()

// Open camera
Button("Scan") {
    viewModel.openCamera()
}

// Check for content
if let content = viewModel.educationalContent {
    Text(content.title)
    Text(content.shortSummary)
    
    // Show quiz
    NavigationLink(destination: DiscoveryQuizView(viewModel: viewModel)) {
        Text("Take Quiz")
    }
}

// Handle errors
if case .error(let message) = viewModel.state {
    Text("Error: \(message)")
    Button("Retry") {
        viewModel.clearError()
    }
}
```

---

## 🎨 Customization

### Colors Used

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Green | `0EB060` | Buttons, highlights, difficulty-Beginner |
| Background | `0A0F0D` | Main background |
| Warning Yellow | `FFB800` | Difficulty-Intermediate |
| Error Red | `FF6B6B` | Difficulty-Advanced, errors |
| Text | `FFFFFF` | Primary text |
| Muted | `FFFFFF` (60%) | Secondary text |

### Change AI Prompt

Edit `buildEducationalPrompt()` in `GeminiAPIService.swift`:

```swift
let prompt = """
Generate content focusing on:
- [Your custom requirements]
- [Additional fields]
"""
```

### Modify Quiz Options

Edit `DiscoveryQuizView.swift`:

```swift
// Change button appearance
.cornerRadius(12)     // Adjust border radius
.stroke(lineWidth: 2) // Adjust border width
```

---

## 🚨 Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `missingAPIKey` | No API key configured | Add to Firebase Remote Config |
| `noTextDetected` | Poor image quality | Improve lighting, clarity |
| `apiError(statusCode)` | API failure | Check API key, quota, network |
| `invalidJSON` | Malformed AI response | Check prompt format |

### Debug Logs

```swift
// Enabled in VisionTextRecognizer
print("✅ Text extraction complete")
print("Detected languages: \(result.detectedLanguages)")
print("Confidence: \(String(format: "%.0f%%", result.confidence * 100))")

// Enabled in GeminiAPIService
print("🎓 Educational content generated successfully")

// Enabled in DiscoveryViewModel
print("❌ Error: \(message)")
```

---

## 📊 State Enum

```swift
enum DiscoveryState {
    case idle                    // Ready for input
    case scanning               // Camera active
    case processingImage        // Image being processed
    case extractingText         // OCR in progress
    case generatingContent      // AI call in progress
    case displayingContent      // Ready to show results
    case error(String)          // Error occurred
}
```

---

## ⚡ Performance

| Operation | Time | Notes |
|-----------|------|-------|
| OCR Extraction | 500ms-1s | Depends on image size |
| Barcode Detection | 100ms | Usually fast |
| Gemini API Call | 3-5s | Network dependent |
| AR Rendering | Real-time | GPU accelerated |

---

## 🔐 API Rate Limits

- **Free Tier:** 60 requests/min, 1M tokens/day
- **Paid Tier:** Higher limits based on plan

Check usage: https://console.cloud.google.com

---

## 📚 Related Components

- `EVScreenTopBar` - Top navigation (Discovery page)
- `EVMainTabNavigationBar` - Bottom tab bar
- `RankView` - Leaderboard (separate feature)
- `LessonView` - Lessons (separate feature)

---

## ✅ Checklist

Before deploying to production:

- [ ] Gemini API key added to Firebase Remote Config
- [ ] Camera permission added to Info.plist
- [ ] ARKit capability enabled
- [ ] Tested on real device
- [ ] Network connectivity verified
- [ ] API quota checked
- [ ] Error messages customized
- [ ] Loading UI polished

---

## 📞 Debugging

### Enable Verbose Logging

Add to `DiscoveryViewModel`:

```swift
private let debug = true

private func log(_ message: String) {
    if debug {
        print("[Discovery] \(message)")
    }
}
```

### Test with Mock Data

```swift
let mockContent = EducationalContent(
    id: "test",
    title: "Test Title",
    detectedObjectName: "Test Object",
    // ... fill other fields
)

viewModel.educationalContent = mockContent
viewModel.state = .displayingContent
```

### Monitor API Calls

Add breakpoint in `generateEducationalContent()`:

```swift
print("📤 Sending request to Gemini API")
print("Text length: \(extractedText.count)")
let content = try await geminiService.generateEducationalContent(from: extractedText)
print("📥 Received response: \(content.title)")
```

---

## 🎓 Learning Resources

- [Vision Framework Guide](https://developer.apple.com/documentation/vision/)
- [ARKit Documentation](https://developer.apple.com/arkit/)
- [Gemini API Docs](https://ai.google.dev/)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)

---

## 📝 Notes

- All API calls use `@MainActor` for thread safety
- Images are processed asynchronously to prevent UI blocking
- Error messages are user-friendly and actionable
- AR view requires device with ARKit support
- Camera requires real device (limited simulator support)

---

Generated: 2024
Last Updated: Discovery Mode Implementation Complete
