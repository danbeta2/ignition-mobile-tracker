//
//  UserProfileManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import CoreData
import Combine

// MARK: - User Profile Manager
@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var userProfile: UserProfileModel?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadUserProfile()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for spark events to update profile
        NotificationCenter.default.publisher(for: .sparkAdded)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.loadUserProfile()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .overloadTriggered)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleOverloadTriggered()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Profile Operations
    func loadUserProfile() {
        isLoading = true
        error = nil
        
        Task {
            await MainActor.run {
                self.userProfile = persistenceController.getOrCreateUserProfile()
                self.isLoading = false
            }
        }
    }
    
    func updateProfile(displayName: String? = nil, avatarIcon: String? = nil, cardBack: String? = nil) {
        Task {
            await MainActor.run {
                var profile = persistenceController.getOrCreateUserProfile()
                
                if let displayName = displayName {
                    profile.displayName = displayName
                }
                if let avatarIcon = avatarIcon {
                    profile.selectedAvatarIcon = avatarIcon
                }
                if let cardBack = cardBack {
                    profile.selectedCardBack = cardBack
                }
                
                persistenceController.updateUserProfile(profile)
                self.userProfile = profile
            }
        }
    }
    
    func resetProgress() {
        Task {
            await MainActor.run {
                var profile = persistenceController.getOrCreateUserProfile()
                
                profile.totalSparks = 0
                profile.totalSparkPoints = 0
                profile.currentFuelLevel = 0
                profile.currentStreak = 0
                profile.totalOverloads = 0
                profile.lastOverloadAt = nil
                
                persistenceController.updateUserProfile(profile)
                self.userProfile = profile
            }
        }
    }
    
    // MARK: - Fuel Gauge & Overload
    func getCurrentFuelPercentage() -> Double {
        return userProfile?.fuelGaugePercentage ?? 0.0
    }
    
    func isInOverloadMode() -> Bool {
        return userProfile?.isOverloadMode ?? false
    }
    
    private func handleOverloadTriggered() {
        // Trigger overload effects
        AudioHapticsManager.shared.overloadTriggered()
        
        // Show overload animation/effects
        NotificationCenter.default.post(name: .showOverloadEffects, object: nil)
    }
    
    // MARK: - Statistics
    func getStreakInfo() -> (current: Int, longest: Int) {
        guard let profile = userProfile else { return (0, 0) }
        return (profile.currentStreak, profile.longestStreak)
    }
    
    func getTotalStats() -> (sparks: Int, points: Int, overloads: Int) {
        guard let profile = userProfile else { return (0, 0, 0) }
        return (profile.totalSparks, profile.totalSparkPoints, profile.totalOverloads)
    }
    
    func getLevelInfo() -> (current: Int, progress: Double, nextLevelPoints: Int) {
        guard let profile = userProfile else { return (1, 0.0, 100) }
        return (profile.level, profile.currentLevelProgress, profile.nextLevelPoints)
    }
}

// MARK: - Additional Notification Names
extension Notification.Name {
    static let showOverloadEffects = Notification.Name("showOverloadEffects")
}
