//
//  SettingsView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 02/10/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Appearance Section
                Section("Appearance") {
                    // Dark Mode
                    Toggle(isOn: $themeManager.isDarkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    .onChange(of: themeManager.isDarkMode) { _, newValue in
                        themeManager.updateDarkMode(newValue)
                        audioHapticsManager.uiTapped()
                    }
                    
                    // Color Blind Friendly
                    Toggle(isOn: $themeManager.isColorBlindFriendly) {
                        Label("Color Blind Mode", systemImage: "eye.fill")
                    }
                    .onChange(of: themeManager.isColorBlindFriendly) { _, newValue in
                        themeManager.updateColorBlindFriendly(newValue)
                        audioHapticsManager.uiTapped()
                    }
                    
                    // Font Scale
                    VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
                        Label("Text Size", systemImage: "textformat.size")
                        
                        HStack {
                            Text("A")
                                .font(.caption)
                            
                            Slider(value: $themeManager.fontScale, in: 0.8...1.5, step: 0.1)
                                .onChange(of: themeManager.fontScale) { _, newValue in
                                    themeManager.updateFontScale(newValue)
                                }
                            
                            Text("A")
                                .font(.title2)
                        }
                    }
                }
                
                // MARK: - Audio & Haptics Section
                Section("Audio & Haptics") {
                    Toggle(isOn: $audioHapticsManager.soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                    }
                    .onChange(of: audioHapticsManager.soundEnabled) { _, _ in
                        audioHapticsManager.uiTapped()
                    }
                    
                    Toggle(isOn: $audioHapticsManager.hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }
                    .onChange(of: audioHapticsManager.hapticsEnabled) { _, _ in
                        audioHapticsManager.uiTapped()
                    }
                    
                    if audioHapticsManager.soundEnabled {
                        VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
                            Label("Volume", systemImage: "speaker.fill")
                            
                            Slider(value: $audioHapticsManager.soundVolume, in: 0...1)
                                .onChange(of: audioHapticsManager.soundVolume) { _, _ in
                                    audioHapticsManager.playSelectionHaptic()
                                }
                        }
                    }
                }
                
                // MARK: - Notifications Section
                Section("Notifications") {
                    Button(action: {
                        // TODO: Navigate to NotificationSettingsView
                    }) {
                        HStack {
                            Label("Notification Settings", systemImage: "bell.fill")
                                .foregroundColor(themeManager.primaryTextColor)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(themeManager.secondaryTextColor)
                                .font(.caption)
                        }
                    }
                }
                
                // MARK: - About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

