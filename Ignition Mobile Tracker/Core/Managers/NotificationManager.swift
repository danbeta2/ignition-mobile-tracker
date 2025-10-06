//
//  NotificationManager.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

// MARK: - Notification Types
enum NotificationType: String, CaseIterable {
    case dailyReminder = "daily_reminder"
    case streakReminder = "streak_reminder"
    case missionDeadline = "mission_deadline"
    case overloadReady = "overload_ready"
    case weeklyReport = "weekly_report"
    case achievementUnlocked = "achievement_unlocked"
    case sparkSuggestion = "spark_suggestion"
    
    var identifier: String {
        return "ignition.notification.\(rawValue)"
    }
    
    var title: String {
        switch self {
        case .dailyReminder:
            return "🔥 Time to Spark!"
        case .streakReminder:
            return "⚡ Keep Your Streak!"
        case .missionDeadline:
            return "🎯 Mission Deadline"
        case .overloadReady:
            return "💥 Overload Ready!"
        case .weeklyReport:
            return "📊 Weekly Report"
        case .achievementUnlocked:
            return "🏆 Achievement Unlocked!"
        case .sparkSuggestion:
            return "💡 Spark Suggestion"
        }
    }
}

// MARK: - Ignition Notification Manager
class IgnitionNotificationManager: ObservableObject {
    static let shared = IgnitionNotificationManager()
    
    @Published var isAuthorized = false
    @Published var notificationSettings: UNNotificationSettings?
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        Task { @MainActor in
            setupNotificationDelegate()
            checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            // Apple compliant: Only request standard notification permissions
            let granted = try await center.requestAuthorization(options: [
                .alert, .badge, .sound
            ])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            // No remote notifications - app is fully offline
            
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                self.notificationSettings = settings
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Remote notifications removed - app is fully offline
    
    // MARK: - Notification Scheduling
    
    func scheduleNotification(
        type: NotificationType,
        title: String? = nil,
        body: String,
        timeInterval: TimeInterval? = nil,
        date: Date? = nil,
        repeats: Bool = false,
        userInfo: [String: Any] = [:]
    ) async {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title ?? type.title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add custom user info
        var finalUserInfo = userInfo
        finalUserInfo["type"] = type.rawValue
        finalUserInfo["timestamp"] = Date().timeIntervalSince1970
        content.userInfo = finalUserInfo
        
        // Create trigger
        let trigger: UNNotificationTrigger?
        
        if let timeInterval = timeInterval {
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: repeats
            )
        } else if let date = date {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: repeats
            )
        } else {
            trigger = nil
        }
        
        let request = UNNotificationRequest(
            identifier: "\(type.identifier)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Scheduled notification: \(type.rawValue)")
        } catch {
            print("❌ Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Smart Notifications
    
    func scheduleDailyReminder(at hour: Int = 19, minute: Int = 0) async {
        // Cancel existing daily reminders
        await cancelNotifications(of: .dailyReminder)
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 Time to Spark!"
        content.body = "Don't forget to record your sparks today!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": NotificationType.dailyReminder.rawValue]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: NotificationType.dailyReminder.identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("✅ Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("❌ Failed to schedule daily reminder: \(error)")
        }
    }
    
    func scheduleStreakReminder() async {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: tomorrow)
        
        guard let reminderTime = reminderTime else { return }
        
        await scheduleNotification(
            type: .streakReminder,
            body: "La tua streak è a rischio! Crea un spark per mantenerla attiva.",
            date: reminderTime
        )
    }
    
    func scheduleMissionDeadline(for mission: IgnitionMissionModel) async {
        guard let expiresAt = mission.expiresAt else { return }
        
        // Schedule 1 hour before deadline
        let reminderTime = Calendar.current.date(byAdding: .hour, value: -1, to: expiresAt)
        guard let reminderTime = reminderTime, reminderTime > Date() else { return }
        
        await scheduleNotification(
            type: .missionDeadline,
            body: "La missione '\(mission.title)' scade tra 1 ora!",
            date: reminderTime,
            userInfo: ["missionId": mission.id.uuidString]
        )
    }
    
    func scheduleOverloadReady() async {
        // Disabled: Overload notifications are now handled via in-app UI only
        // to comply with App Store notification limits (max 1 per day)
        print("ℹ️ Overload ready (in-app notification only)")
    }
    
    func scheduleWeeklyReport() async {
        // Schedule for Sunday at 18:00
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0
        
        await scheduleNotification(
            type: .weeklyReport,
            body: "Your weekly report is ready! Discover your progress.",
            date: Calendar.current.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime),
            repeats: true
        )
    }
    
    func scheduleAchievementUnlocked(title: String, description: String) async {
        // Disabled: Achievements are now shown via in-app UI only
        // to comply with App Store notification limits (max 1 per day)
        print("🎉 Achievement unlocked: \(title) (in-app notification only)")
    }
    
    func scheduleSparkSuggestion(category: SparkCategory) async {
        // Disabled: Spark suggestions are now shown via in-app UI only
        // to comply with App Store notification limits (max 1 per day)
        print("💡 Spark suggestion for \(category.displayName) (in-app notification only)")
    }
    
    // MARK: - Notification Management
    
    func cancelNotifications(of type: NotificationType) async {
        let identifiers = [type.identifier]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    func getPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        await MainActor.run {
            self.pendingNotifications = requests
        }
    }
    
    // MARK: - Notification Delegate
    
    private func setupNotificationDelegate() {
        center.delegate = NotificationDelegate.shared
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let typeString = userInfo["type"] as? String,
           let type = NotificationType(rawValue: typeString) {
            handleNotificationTap(type: type, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: NotificationType, userInfo: [AnyHashable: Any]) {
        Task { @MainActor in
            switch type {
            case .dailyReminder, .sparkSuggestion:
                // Navigate to tracker tab
                // Navigation will be handled when app becomes active
                print("Navigate to tracker")
                
            case .streakReminder:
                // Navigate to home tab to show streak
                print("Navigate to home")
                
            case .missionDeadline:
                // Navigate to missions tab
                print("Navigate to missions")
                
            case .overloadReady:
                // Navigate to home and trigger overload
                print("Navigate to home for overload")
                
            case .weeklyReport:
                // Navigate to stats tab
                print("Navigate to stats")
                
            case .achievementUnlocked:
                // Show achievement details
                print("Navigate to home for achievement")
            }
        }
    }
}

// MARK: - Notification Extensions
extension IgnitionNotificationManager {
    
    func scheduleSmartReminders(based userProfile: UserProfileModel) async {
        // Apple App Store Compliance: MAX 1 notification per day
        // Only schedule ONE daily reminder at user's preferred time
        
        let lastSparkHour = userProfile.lastSparkDate.map { 
            Calendar.current.component(.hour, from: $0) 
        } ?? 19
        
        // Schedule ONLY daily reminder (repeating, once per day)
        await self.scheduleDailyReminder(at: lastSparkHour)
        
        print("✅ Notification scheduled: 1 daily reminder at \(lastSparkHour):00 (App Store compliant)")
    }
    
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            // Use iOS 17+ API for badge management
            try? await UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
}
