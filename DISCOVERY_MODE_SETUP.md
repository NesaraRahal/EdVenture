# EdVenture Discovery Mode - Complete Implementation Guide

## 🎯 Feature Overview

The Discovery Mode allows users to:
1. **Scan** real-world educational objects (books, posters, labels, documents)
2. **Extract** text using Apple Vision framework (OCR)
3. **Detect** barcodes/ISBN codes
4. **Generate** AI-powered educational content using Google Gemini API
5. **View** interactive AR overlays with learning content
6. **Take** built-in quiz questions

Reference screenshot shows "The Trial" book cover being scanned in the DISCOVERY tab with "ACTIVE FOCUS" label.

---

## 📋 Implementation Files Created

### Core Services

| File | Purpose |
|------|---------|
| `Core/GeminiAPIService.swift` | REST API integration with Google Gemini, Codable models for structured content generation |
| `Core/VisionTextRecognizer.swift` | Apple Vision Framework OCR + Barcode detection |
| `Core/CameraViewController.swift` | VisionKit camera integration with capture controls |
| `Core/APIConfigurationService.swift` | Firebase Remote Config setup and API key management |

### Discovery Feature

| File | Purpose |
|------|---------|
| `Features/Discovery/DiscoveryViewModel.swift` | State management, image processing pipeline, error handling |
| `Features/Discovery/DiscoveryView.swift` | Main UI with camera button, content display, action buttons |
| `Features/Discovery/AROverlayView.swift` | AR content overlay with floating cards, quiz buttons, achievement badges |

---

## 🔧 Setup Instructions (Required)

### Step 1: Get Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click **"Create API key"**
3. Copy the key (you'll need it in Step 2)
4. Keep this key **private and secure**

### Step 2: Add to Firebase Remote Config

1. Go to **Firebase Console** → Your Project → **Remote Config**
2. Click **"Create config"**
3. Add new parameter:
   - **Name:** `gemini_api_key`
   - **Type:** String
   - **Default value:** [Paste your Gemini API key]
4. Click **"Publish"**

### Step 3: Add iOS Capabilities

1. In Xcode, select **EdVenture** project
2. Select **EdVenture** target
3. Go to **Signing & Capabilities**
4. Click **"+ Capability"** and add:
   - **Camera**
   - **ARKit** (if not already present)

### Step 4: Update Info.plist

Add these permissions to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan educational materials like books, posters, and labels for instant learning content.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location for accurate AR experience positioning and geolocation-based discovery.</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
    <string>camera</string>
</array>
```

**To edit Info.plist in Xcode:**
1. Right-click `Info.plist` in Project Navigator
2. Select **Open As** → **Source Code**
3. Paste the above keys
4. Right-click again and select **Open As** → **Property List**

---

## ✅ Architecture Flow

```
User opens Camera
        ↓
[CameraViewController] captures image
        ↓
[DiscoveryViewModel.handleImageCapture()] receives UIImage
        ↓
[VisionTextRecognizer.recognizeText()] extracts text + barcodes
        ↓
[GeminiAPIService.generateEducationalContent()] calls Gemini API
        ↓
AI Response parsed into [EducationalContent] model
        ↓
[DiscoveryView] displays extracted content
        ↓
User taps "View AR" button
        ↓
[AROverlayView] shows floating cards with learning content
        ↓
User can take quiz or scan again
```

---

## 🎮 Usage Guide

### For Users

1. **Navigate to Discovery tab** (bottom bar)
2. **Tap "Start Scanning"** button
3. **Point at educational material** (book cover, poster, etc.)
4. **Tap capture button** when content is in focus
5. **Wait for processing** (text extraction → AI generation → ~3-5 seconds)
6. **View results** with title, summary, facts, learning points
7. **Tap "View AR"** to see interactive AR overlay
8. **"Take Quiz"** button triggers quiz questions
9. **"Scan Again"** to process another object

### For Developers

**Initialize API Key (automatic on app launch):**
```swift
// EdVentureApp.swift already calls this in init()
APIConfigurationService.shared.setupAPIKeys()
```

**Manual image processing:**
```swift
let viewModel = DiscoveryViewModel()
if let image = UIImage(named: "book_cover") {
    viewModel.processLocalImage(image)
}
```

**Access extracted content:**
```swift
if let content = viewModel.educationalContent {
    print("Title: \(content.title)")
    print("Summary: \(content.shortSummary)")
    print("Difficulty: \(content.difficultyLevel)")
}
```

---

## 🛠️ Configuration Options

### Change OCR Language

In `VisionTextRecognizer.swift`, modify `recognizeText()`:

```swift
textRequest.recognitionLanguages = ["en-US", "es", "fr", "de"]
```

Supported languages: `en-US`, `en-GB`, `es`, `fr`, `de`, `it`, `ja`, `ko`, `zh-Hans`, `zh-Hant`, `pt-BR`, `ru`, etc.

### Customize AI Prompt

In `GeminiAPIService.swift`, edit `buildEducationalPrompt()`:

```swift
let prompt = """
Analyze this text and generate:
- Custom difficulty levels (Easy, Medium, Hard)
- Different quiz format (True/False, Multiple Choice, Fill Blank)
- Cultural context or historical significance
"""
```

### Adjust Processing States

In `DiscoveryView.swift`, customize `processingStatusText`:

```swift
case .extractingText:
    return "🔍 Reading text from image..."
case .generatingContent:
    return "🤖 AI is creating learning content..."
```

### Modify AR Overlay Cards

In `AROverlayView.swift`, edit card styling:

```swift
// Change colors
.fill(Color(hex: "0EB060"))

// Change animations
.transition(.move(edge: .bottom).combined(with: .opacity))

// Add new cards
FloatingCustomCard()
```

---

## 📊 Data Models

### EducationalContent (Main Model)

```swift
struct EducationalContent {
    let id: String
    let title: String
    let detectedObjectName: String
    let shortSummary: String
    let educationalFacts: [String]
    let difficultyLevel: String // "Beginner", "Intermediate", "Advanced"
    let keyLearningPoints: [String]
    let quizQuestions: [QuizQuestion]
    let arOverlayCaption: String
    let extractedText: String
    let generatedAt: Date
}
```

### QuizQuestion (Quiz Model)

```swift
struct QuizQuestion {
    let id: String
    let question: String
    let options: [String] // 4 options
    let correctAnswerIndex: Int
    let explanation: String
}
```

### VisionTextRecognitionResult

```swift
struct VisionTextRecognitionResult {
    let extractedText: String
    let barcodes: [BarcodeInfo]
    let detectedLanguages: [String]
    let confidence: Float // 0.0 - 1.0
}
```

---

## 🐛 Troubleshooting

### Issue: Camera doesn't open

**Solution:**
- Ensure app has Camera permission in Settings
- Test on **real device** (simulator has limited camera support)
- Check Info.plist has `NSCameraUsageDescription`
- Verify Signing & Capabilities has Camera enabled

### Issue: No text detected / "No readable text detected in image"

**Solution:**
- Ensure **good lighting** on the object
- Text should be **clearly visible** and **not tilted**
- Try with **larger fonts** (book titles, poster headers)
- Avoid blurry or low-contrast images
- Object should be **centered** in frame

### Issue: API Error / Gemini returns error status

**Solution:**
- Verify API key is valid at [Google AI Studio](https://makersuite.google.com/app/apikey)
- Ensure key is **correctly added to Firebase Remote Config**
- Check **network connectivity**
- Verify Gemini API quota hasn't been exceeded
- Check API key has **correct permissions**

### Issue: AR overlay not displaying / "Gesture required before AR"

**Solution:**
- ARKit requires **iOS 13.0+** and **A11 chip or newer**
- Test on **real device** (simulator AR support is limited)
- Ensure device has **gyroscope and accelerometer**
- Try moving device around to trigger AR tracking
- Check ARKit capabilities in Settings

### Issue: Processing takes too long

**Solution:**
- **Text extraction:** ~500ms-1s (depends on image size)
- **AI generation:** ~3-5s (depends on text length and API response time)
- **Network speed:** Slower internet increases API call time
- Reduce extracted text length for faster processing
- Consider using free tier vs. paid tier API limits

### Issue: Firebase Remote Config not loading

**Solution:**
- Check internet connection
- Ensure Firebase project is **properly configured**
- Verify Remote Config has **published parameters**
- Check Firebase Console → Remote Config → Conditions
- Try restarting app or forcing Remote Config fetch

---

## 📈 Performance Tips

1. **Image Size:** Compress images before sending to API
   ```swift
   let compressed = image.jpegData(compressionQuality: 0.7)
   ```

2. **Barcode Detection:** Check barcodes first before full OCR
   ```swift
   let barcodes = visionRecognizer.detectBarcodes(from: image)
   if !barcodes.isEmpty { /* use barcode metadata */ }
   ```

3. **Caching:** Store processed content locally
   ```swift
   viewModel.scanHistory // Already cached in-memory
   // TODO: Implement Core Data persistence
   ```

4. **OCR Languages:** Only request necessary languages
   ```swift
   textRequest.recognitionLanguages = ["en-US"] // Faster
   ```

---

## 🔐 Security Best Practices

1. **Never commit API key to git:**
   ```bash
   # Add to .gitignore
   echo "GoogleService-Info*.plist" >> .gitignore
   echo "*api_key*" >> .gitignore
   ```

2. **Use Firebase Remote Config** for key rotation without app updates

3. **Implement rate limiting** to prevent API abuse

4. **Validate user input** before sending to Gemini API

5. **Store sensitive data** in Keychain (not UserDefaults)
   ```swift
   // TODO: Update APIConfigurationService to use Keychain
   ```

---

## 📚 API Rate Limits

**Free Tier (Gemini API):**
- 60 requests per minute
- 1 million tokens per day

**Upgrade if needed:** https://makersuite.google.com/app/billing

Check your usage in [Google Cloud Console](https://console.cloud.google.com)

---

## 🎓 Educational Content Examples

The AI will generate content like:

### Example 1: "The Trial" (Book)
```json
{
  "title": "The Trial",
  "detectedObjectName": "Book Cover",
  "difficulty": "Advanced",
  "summary": "Kafka's surrealist novel exploring bureaucratic absurdity",
  "facts": ["Published 1925", "Written in German", "Existentialist themes"],
  "learningPoints": ["Surrealism", "Existentialism", "Bureaucracy"],
  "questions": [...]
}
```

### Example 2: "Periodic Table" (Poster)
```json
{
  "title": "Periodic Table of Elements",
  "detectedObjectName": "Educational Poster",
  "difficulty": "Beginner",
  "summary": "Visual reference of all known chemical elements",
  "facts": ["118 elements", "Organized by atomic number", "Groups show similar properties"],
  "learningPoints": ["Atomic structure", "Element properties", "Chemical bonding"],
  "questions": [...]
}
```

---

## 🚀 Next Steps

1. ✅ **Implement:** All core Discovery Mode files created
2. ⏳ **Configure:** Add Gemini API key to Firebase Remote Config
3. ⏳ **Test:** Build on real device and test end-to-end
4. ⏳ **Enhance:** Add scan history persistence with Core Data
5. ⏳ **Optimize:** Implement local image caching
6. ⏳ **Monitor:** Track API usage and user engagement

---

## 📞 Support Resources

- **Gemini API Docs:** https://ai.google.dev/
- **Vision Framework Docs:** https://developer.apple.com/documentation/vision/
- **ARKit Guide:** https://developer.apple.com/arkit/
- **Firebase Remote Config:** https://firebase.google.com/docs/remote-config

---

## ✨ Feature Completion Checklist

- [x] Camera integration (VisionKit)
- [x] Text extraction (Vision Framework OCR)
- [x] Barcode detection (ISBN codes)
- [x] Gemini API integration (REST)
- [x] Content models (Codable structures)
- [x] AI prompt engineering
- [x] DiscoveryViewModel (state management)
- [x] Discovery UI (camera, content display)
- [x] AR overlay view (floating cards)
- [x] Quiz integration
- [x] Error handling
- [x] Loading states
- [ ] Scan history persistence (Core Data)
- [ ] Achievement badges
- [ ] Social sharing
- [ ] Offline mode support

---

## 🎉 You're Ready!

The Discovery Mode is fully implemented. Now:

1. **Add your Gemini API key** to Firebase Remote Config
2. **Build on a real device** (iOS 13.0+)
3. **Test with various objects** (books, posters, labels)
4. **Gather user feedback** on content quality
5. **Iterate on AI prompts** for better results

Enjoy your students discovering the world through AR! 🌍📚
