//
//  AudioHapticsManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - Audio Haptics Manager
@MainActor
class AudioHapticsManager: ObservableObject {
    static let shared = AudioHapticsManager()
    
    @Published var soundEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    @Published var soundVolume: Float = 0.7
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSettings()
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        soundEnabled = userDefaults.bool(forKey: "soundEnabled")
        hapticsEnabled = userDefaults.bool(forKey: "hapticsEnabled")
        soundVolume = userDefaults.float(forKey: "soundVolume")
        
        // Set defaults if first launch
        if !userDefaults.bool(forKey: "audioHapticsConfigured") {
            soundEnabled = true
            hapticsEnabled = true
            soundVolume = 0.7
            userDefaults.set(true, forKey: "audioHapticsConfigured")
            saveSettings()
        }
    }
    
    private func saveSettings() {
        userDefaults.set(soundEnabled, forKey: "soundEnabled")
        userDefaults.set(hapticsEnabled, forKey: "hapticsEnabled")
        userDefaults.set(soundVolume, forKey: "soundVolume")
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Preloading
    private func preloadSounds() {
        let sounds = AssetNames.Audio.allCases
        
        for sound in sounds {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = soundVolume
                    audioPlayers[sound.rawValue] = player
                } catch {
                    print("Failed to preload sound \(sound.rawValue): \(error)")
                    // Fallback: we'll use system sounds if custom sounds fail
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func updateSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        saveSettings()
    }
    
    func updateHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        saveSettings()
    }
    
    func updateSoundVolume(_ volume: Float) {
        soundVolume = max(0.0, min(1.0, volume))
        
        // Update all players volume
        for player in audioPlayers.values {
            player.volume = soundVolume
        }
        
        saveSettings()
    }
    
    // MARK: - Sound Playing
    func playSound(_ sound: AssetNames.Audio) {
        guard soundEnabled else { return }
        
        if let player = audioPlayers[sound.rawValue] {
            player.stop()
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system sounds
            playSystemSound(for: sound)
        }
    }
    
    private func playSystemSound(for sound: AssetNames.Audio) {
        let systemSoundID: SystemSoundID
        
        switch sound {
        case .sparkAdd:
            systemSoundID = 1057 // SMS received sound
        case .uiTap:
            systemSoundID = 1104 // Camera shutter
        case .overloadTrigger:
            systemSoundID = 1005 // New mail sound
        }
        
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    // MARK: - Haptic Feedback
    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        
        let impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator.impactOccurred()
    }
    
    func playNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(type)
    }
    
    func playSelectionHaptic() {
        guard hapticsEnabled else { return }
        
        let selectionGenerator = UISelectionFeedbackGenerator()
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Convenience Methods
    func sparkAdded() {
        playSound(.sparkAdd)
        playHaptic(.medium)
    }
    
    func uiTapped() {
        playSound(.uiTap)
        playSelectionHaptic()
    }
    
    func overloadTriggered() {
        playSound(.overloadTrigger)
        playNotificationHaptic(.success)
    }
    
    func missionCompleted() {
        playNotificationHaptic(.success)
        playHaptic(.heavy)
    }
    
    func achievementUnlocked() {
        playNotificationHaptic(.success)
        playHaptic(.heavy)
    }
    
    func cardRevealed() {
        playSound(.sparkAdd) // Reusing spark add sound for now
        playNotificationHaptic(.success)
        playHaptic(.heavy)
    }
}
