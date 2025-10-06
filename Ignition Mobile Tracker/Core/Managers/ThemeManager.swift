//
//  ThemeManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import Combine

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = true
    @Published var fontScale: Double = 1.0
    @Published var isColorBlindFriendly: Bool = false
    @Published var reduceMotion: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        isDarkMode = userDefaults.bool(forKey: "isDarkMode")
        fontScale = userDefaults.double(forKey: "fontScale")
        isColorBlindFriendly = userDefaults.bool(forKey: "isColorBlindFriendly")
        reduceMotion = userDefaults.bool(forKey: "reduceMotion")
        
        // Set defaults if first launch
        if !userDefaults.bool(forKey: "hasLaunchedBefore") {
            isDarkMode = true
            fontScale = 1.0
            isColorBlindFriendly = false
            reduceMotion = false
            userDefaults.set(true, forKey: "hasLaunchedBefore")
            saveSettings()
        }
    }
    
    private func saveSettings() {
        userDefaults.set(isDarkMode, forKey: "isDarkMode")
        userDefaults.set(fontScale, forKey: "fontScale")
        userDefaults.set(isColorBlindFriendly, forKey: "isColorBlindFriendly")
        userDefaults.set(reduceMotion, forKey: "reduceMotion")
    }
    
    // MARK: - Public Methods
    func updateDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        saveSettings()
    }
    
    func updateFontScale(_ scale: Double) {
        fontScale = max(0.8, min(1.5, scale))
        saveSettings()
    }
    
    func updateColorBlindFriendly(_ enabled: Bool) {
        isColorBlindFriendly = enabled
        saveSettings()
    }
    
    func updateReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        saveSettings()
    }
    
    // MARK: - Dynamic Colors
    var primaryColor: Color {
        return isColorBlindFriendly ? Color.blue : IgnitionColors.ignitionOrange
    }
    
    var secondaryColor: Color {
        return isColorBlindFriendly ? Color.cyan : IgnitionColors.mediumGray
    }
    
    var backgroundColor: Color {
        return isDarkMode ? IgnitionColors.primaryBackground : Color.white
    }
    
    var textColor: Color {
        return isDarkMode ? IgnitionColors.primaryText : Color.black
    }
    
    var primaryTextColor: Color {
        return isDarkMode ? IgnitionColors.primaryText : Color.black
    }
    
    var secondaryTextColor: Color {
        return isDarkMode ? IgnitionColors.secondaryText : IgnitionColors.mediumGray
    }
    
    var cardColor: Color {
        return isDarkMode ? IgnitionColors.cardBackground : Color.gray.opacity(0.1)
    }
    
    var cardBackgroundColor: Color {
        return isDarkMode ? IgnitionColors.cardBackground : Color.gray.opacity(0.1)
    }
    
    var shadowColor: Color {
        return isDarkMode ? IgnitionShadow.medium : IgnitionShadow.small
    }
    
    // MARK: - Dynamic Fonts
    func scaledFont(_ font: Font) -> Font {
        // This is a simplified implementation
        // In a real app, you'd want to properly scale font sizes
        return font
    }
    
    // MARK: - Animation Duration
    var animationDuration: Double {
        return reduceMotion ? 0.1 : 0.3
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
