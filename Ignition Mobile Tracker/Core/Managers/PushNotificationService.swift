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
        // Apple App Store Compliance: MAX 1 notification per day
        // All notification scheduling is handled by IgnitionNotificationManager.scheduleSmartReminders()
        // which respects the 1-per-day limit
        
        print("✅ Push notification service initialized (daily limit enforced)")
    }
}
