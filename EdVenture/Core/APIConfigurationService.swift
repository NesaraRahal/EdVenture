import SwiftUI
import Firebase
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

// MARK: - API Configuration Setup

/// Helper to load Gemini API key from Firebase Remote Config or environment
@MainActor
class APIConfigurationService {
    static let shared = APIConfigurationService()
#if canImport(FirebaseRemoteConfig)
   private let remoteConfig = RemoteConfig.remoteConfig()
#endif
    
    func setupAPIKeys() {
      #if canImport(FirebaseRemoteConfig)
      // Fetch Gemini API key from Firebase Remote Config (if module is linked)
      fetchGeminiAPIKey()
      #else
      // Fallback: read from Info.plist when FirebaseRemoteConfig is unavailable
      if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
         !apiKey.isEmpty {
         GeminiAPIService.shared.setAPIKey(apiKey)
         print("✅ Gemini API key loaded from Info.plist")
      } else {
         print("⚠️ FirebaseRemoteConfig module is not available.")
         print("📝 Add GEMINI_API_KEY to Info.plist or link FirebaseRemoteConfig.")
      }
      #endif
    }
    
   #if canImport(FirebaseRemoteConfig)
    private func fetchGeminiAPIKey() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour cache
        remoteConfig.configSettings = settings
        
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                print("⚠️ Remote Config fetch error: \(error)")
                return
            }
            
            let apiKey = self.remoteConfig["gemini_api_key"].stringValue
            if !apiKey.isEmpty {
                GeminiAPIService.shared.setAPIKey(apiKey)
                print("✅ Gemini API key loaded from Firebase Remote Config")
            } else {
                print("⚠️ Gemini API key not found in Firebase Remote Config")
                print("📝 To set up: Go to Firebase Console → Remote Config → Add parameter 'gemini_api_key'")
            }
        }
    }
      #endif
}

// MARK: - Setup Instructions

/*
 ============================================================
 DISCOVERY MODE - SETUP INSTRUCTIONS
 ============================================================
 
 To complete the Discovery Mode implementation, follow these steps:
 
 1. GET GEMINI API KEY:
    - Go to https://makersuite.google.com/app/apikey
    - Create a new API key
    - Copy the key (keep it safe!)
 
 2. ADD TO FIREBASE REMOTE CONFIG:
    a) Go to Firebase Console → Your Project
    b) Navigate to Remote Config
    c) Click "Create config"
    d) Add parameter:
       Name: "gemini_api_key"
       Type: String
       Default value: [Your Gemini API Key]
    e) Publish
 
 3. ADD REQUIRED CAPABILITIES:
    a) In Xcode, select EdVenture project
    b) Select target
    c) Go to Signing & Capabilities
    d) Click "+ Capability"
    e) Add these capabilities:
       - Camera
       - Location Services (for ARKit)
       - App Sandbox (if building for macOS)
 
 4. UPDATE INFO.PLIST:
    Add these keys to Info.plist (or use Xcode):
    
    <key>NSCameraUsageDescription</key>
    <string>We need access to your camera to scan educational materials and objects.</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We use your location for AR experience positioning.</string>
    
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arkit</string>
        <string>camera</string>
    </array>
 
 5. TEST THE FEATURE:
    - Build and run on a real device (simulator has limited AR support)
    - Navigate to Discovery tab
    - Tap "Start Scanning"
    - Point at a book, poster, or document with text
    - Capture the image
    - Wait for text extraction and AI processing
    - View the AR overlay
 
 6. OPTIONAL: STORE SCAN HISTORY
    Implement Core Data model to persist scanned content:
    
    - Create ScanHistory entity with:
      * id (UUID)
      * title (String)
      * content (Educational Content JSON)
      * timestamp (Date)
      * image (Data - base64 encoded)
    
    - Update DiscoveryViewModel:
      * loadScanHistory() to fetch from Core Data
      * saveScanToHistory() to persist scans
 
 ============================================================
 ARCHITECTURE OVERVIEW
 ============================================================
 
 VisionKit Camera
        ↓
 CameraViewController
        ↓
 CameraViewControllerWrapper (SwiftUI bridge)
        ↓
 DiscoveryViewModel
        ↓
 VisionTextRecognizer (Vision Framework OCR)
        ↓
 Extracted Text + Barcodes
        ↓
 GeminiAPIService (REST to Gemini API)
        ↓
 AI-Generated Educational Content
        ↓
 DiscoveryView (Display)
        ↓
 AROverlayView (AR Display with RealityKit)
 
 ============================================================
 CUSTOMIZATION OPTIONS
 ============================================================
 
 1. CHANGE OCR LANGUAGE:
    In VisionTextRecognizer.recognizeText():
    textRequest.recognitionLanguages = ["es", "fr", "de"] // Add your languages
 
 2. MODIFY AI PROMPT:
    In GeminiAPIService.buildEducationalPrompt():
    Adjust the prompt to generate different content types
 
 3. CUSTOMIZE AR OVERLAY:
    In AROverlayView:
    - Change card animations
    - Add more overlay elements
    - Adjust difficulty color scheme
 
 4. ADJUST PROCESSING UI:
    In DiscoveryView:
    - Modify progress indicators
    - Add custom loading animations
    - Personalize error messages
 
 ============================================================
 TROUBLESHOOTING
 ============================================================
 
 • Camera not opening?
   → Check Info.plist permissions
   → Test on real device (not simulator)
 
 • No text detected?
   → Ensure good lighting and focus
   → Try with clearer text/labels
   → Check text size (not too small)
 
 • API errors?
   → Verify Gemini API key is valid
   → Check network connectivity
   → Monitor Firebase Remote Config
 
 • AR not working?
   → ARKit requires iOS 13.0+
   → Test on supported device with A11 or newer
   → Enable ARCore capabilities
 
 ============================================================
 */
