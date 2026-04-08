import Foundation
import UIKit
import AudioToolbox
import AVFoundation

enum EVSoundEvent {
    case click
    case hint
    case correct
    case wrong
    case next

    var resourceName: String {
        switch self {
        case .click: return "ui_click"
        case .hint: return "ui_hint"
        case .correct: return "ui_correct"
        case .wrong: return "ui_wrong"
        case .next: return "ui_next"
        }
    }
}

@MainActor
enum EVAccessibilitySupport {
    static let hapticKey = "accessibility.hapticFeedback"
    static let soundKey = "accessibility.soundEffects"
    static let readerKey = "accessibility.screenReader"
    static let dynamicTextKey = "accessibility.dynamicText"
    private static let synthesizer = AVSpeechSynthesizer()
    private static var sfxPlayers: [String: AVAudioPlayer] = [:]

    static func isEnabled(_ key: String, default defaultValue: Bool = true) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }

    static func playTapFeedback() {
        if isEnabled(hapticKey) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }

        if isEnabled(soundKey) {
            playSound(.click)
        }
    }

    static func playSound(_ event: EVSoundEvent) {
        guard isEnabled(soundKey) else { return }

        let key = event.resourceName

        if let existing = sfxPlayers[key] {
            existing.currentTime = 0
            existing.play()
            return
        }

        let bundleURL = Bundle.main.url(forResource: key, withExtension: "wav", subdirectory: "Resources/SFX")
            ?? Bundle.main.url(forResource: key, withExtension: "wav")

        if let url = bundleURL,
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            sfxPlayers[key] = player
            player.play()
            return
        }

        // Fallback if custom WAV is unavailable in bundle.
        AudioServicesPlaySystemSound(1104)
    }

    static func announce(_ message: String, force: Bool = false) {
        guard force || isEnabled(readerKey) else { return }

        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Always provide TTS for in-app screen reader.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)

        // If VoiceOver is running, also post native accessibility announcement.
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: trimmed)
        }
    }
}
