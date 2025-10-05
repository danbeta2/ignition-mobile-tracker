//
//  PushNotificationService.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import Foundation
import UIKit
import UserNotifications
import Combine

// MARK: - Push Notification Service
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var deviceToken: String?
    @Published var isRegisteredForRemoteNotifications = false
    
    private override init() {
        super.init()
        setupNotificationObservers()
    }
    
    // MARK: - Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceTokenReceived),
            name: .deviceTokenReceived,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteNotificationReceived),
            name: .remoteNotificationReceived,
            object: nil
        )
    }
    
    // MARK: - Registration
    
    func registerForPushNotifications() async {
        let authorizationGranted = await IgnitionNotificationManager.shared.requestAuthorization()
        
        if authorizationGranted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    @objc private func handleDeviceTokenReceived(_ notification: Notification) {
        guard let tokenData = notification.object as? Data else { return }
        
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        self.isRegisteredForRemoteNotifications = true
        
        print("📱 Device token received: \(token)")
        
        // Send token to your server
        Task {
            await sendTokenToServer(token)
        }
    }
    
    @objc private func handleRemoteNotificationReceived(_ notification: Notification) {
        guard let userInfo = notification.object as? [AnyHashable: Any] else { return }
        
        print("📨 Remote notification received: \(userInfo)")
        
        // Process remote notification
        processRemoteNotification(userInfo)
    }
    
    // MARK: - Server Communication
    
    private func sendTokenToServer(_ token: String) async {
        // This would send the token to your backend server
        // For now, we'll just store it locally
        UserDefaults.standard.set(token, forKey: "deviceToken")
        
        print("🚀 Token sent to server: \(token)")
    }
    
    private func processRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let aps = userInfo["aps"] as? [String: Any] else { return }
        
        // Handle different types of push notifications
        if let customData = userInfo["custom"] as? [String: Any] {
            handleCustomNotification(customData)
        }
        
        // Update badge if needed
        if let badge = aps["badge"] as? Int {
            Task { @MainActor in
                // Use iOS 17+ API for badge management
                try? await UNUserNotificationCenter.current().setBadgeCount(badge)
            }
        }
    }
    
    private func handleCustomNotification(_ data: [String: Any]) {
        guard let type = data["type"] as? String else { return }
        
        switch type {
        case "mission_update":
            handleMissionUpdate(data)
        case "achievement_unlock":
            handleAchievementUnlock(data)
        case "social_interaction":
            handleSocialInteraction(data)
        case "system_announcement":
            handleSystemAnnouncement(data)
        default:
            print("Unknown notification type: \(type)")
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleMissionUpdate(_ data: [String: Any]) {
        // Handle mission-related push notifications
        print("🎯 Mission update received: \(data)")
    }
    
    private func handleAchievementUnlock(_ data: [String: Any]) {
        // Handle achievement unlock notifications
        print("🏆 Achievement unlocked: \(data)")
        
        if let title = data["title"] as? String,
           let description = data["description"] as? String {
            Task {
                await IgnitionNotificationManager.shared.scheduleAchievementUnlocked(
                    title: title,
                    description: description
                )
            }
        }
    }
    
    private func handleSocialInteraction(_ data: [String: Any]) {
        // Handle social features (if implemented)
        print("👥 Social interaction: \(data)")
    }
    
    private func handleSystemAnnouncement(_ data: [String: Any]) {
        // Handle system-wide announcements
        print("📢 System announcement: \(data)")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let deviceTokenReceived = Notification.Name("deviceTokenReceived")
    static let remoteNotificationReceived = Notification.Name("remoteNotificationReceived")
}

// MARK: - App Delegate Integration
extension PushNotificationService {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(
            name: .deviceTokenReceived,
            object: deviceToken
        )
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
        isRegisteredForRemoteNotifications = false
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .remoteNotificationReceived,
            object: userInfo
        )
    }
}

// MARK: - Smart Notification Scheduling
extension PushNotificationService {
    
    func scheduleIntelligentNotifications(for userProfile: UserProfileModel) async {
        // Analyze user behavior and schedule smart notifications
        
        // 1. Streak Protection
        if userProfile.currentStreak > 0 {
            await scheduleStreakProtectionNotifications(streak: userProfile.currentStreak)
        }
        
        // 2. Mission Reminders
        await scheduleMissionReminders()
        
        // 3. Engagement Boost
        if shouldBoostEngagement(userProfile) {
            await scheduleEngagementBoostNotifications()
        }
        
        // 4. Weekly Goals
        await scheduleWeeklyGoalNotifications(userProfile)
    }
    
    private func scheduleStreakProtectionNotifications(streak: Int) async {
        let importance = min(streak / 7, 5) // Increase importance with longer streaks
        
        // Guard against invalid range (importance must be >= 1)
        guard importance >= 1 else {
            print("⚠️ Streak too low (\(streak)) to schedule protection notifications")
            return
        }
        
        for i in 1...importance {
            let delay = TimeInterval(i * 3600) // Every hour
            await IgnitionNotificationManager.shared.scheduleNotification(
                type: .streakReminder,
                body: "🔥 \(streak)-day streak! Don't lose it now!",
                timeInterval: delay
            )
        }
    }
    
    private func scheduleMissionReminders() async {
        // This would integrate with MissionManager to get active missions
        // For now, we'll schedule a generic mission reminder
            await IgnitionNotificationManager.shared.scheduleNotification(
                type: .missionDeadline,
                body: "🎯 You have missions expiring! Complete them to earn points.",
                timeInterval: 7200 // 2 hours
            )
    }
    
    private func shouldBoostEngagement(_ userProfile: UserProfileModel) -> Bool {
        // Check if user needs engagement boost
        guard let lastSparkDate = userProfile.lastSparkDate else { return true }
        
        let daysSinceLastSpark = Calendar.current.dateComponents([.day], from: lastSparkDate, to: Date()).day ?? 0
        return daysSinceLastSpark > 1
    }
    
    private func scheduleEngagementBoostNotifications() async {
        let messages = [
            "💡 Do you have any interesting ideas to share?",
            "⚡ Even a small spark can make a difference!",
            "🌟 Your progress is waiting for you!",
            "🚀 Ready for the next level?"
        ]
        
        for (index, message) in messages.enumerated() {
            await IgnitionNotificationManager.shared.scheduleNotification(
                type: .sparkSuggestion,
                body: message,
                timeInterval: TimeInterval((index + 1) * 1800) // Every 30 minutes
            )
        }
    }
    
    private func scheduleWeeklyGoalNotifications(_ userProfile: UserProfileModel) async {
        // Calculate weekly goal progress
        let weeklyTarget = 7 // 1 spark per day
        let currentWeekSparks = calculateCurrentWeekSparks(userProfile)
        
        if currentWeekSparks < weeklyTarget {
            let remaining = weeklyTarget - currentWeekSparks
            await IgnitionNotificationManager.shared.scheduleNotification(
                type: .weeklyReport,
                body: "📊 You need \(remaining) more spark\(remaining == 1 ? "" : "s") to reach your weekly goal!",
                timeInterval: 3600 // 1 hour
            )
        }
    }
    
    private func calculateCurrentWeekSparks(_ userProfile: UserProfileModel) -> Int {
        // This would calculate sparks created this week
        // For now, return a placeholder
        return userProfile.totalSparks > 7 ? 7 : Int(userProfile.totalSparks)
    }
}
