//
//  NotificationManager.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
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
            return "🔥 Tempo di Spark!"
        case .streakReminder:
            return "⚡ Mantieni la Streak!"
        case .missionDeadline:
            return "🎯 Missione in Scadenza"
        case .overloadReady:
            return "💥 Overload Pronto!"
        case .weeklyReport:
            return "📊 Report Settimanale"
        case .achievementUnlocked:
            return "🏆 Achievement Sbloccato!"
        case .sparkSuggestion:
            return "💡 Suggerimento Spark"
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
            let granted = try await center.requestAuthorization(options: [
                .alert, .badge, .sound, .provisional, .criticalAlert
            ])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
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
    
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
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
        content.title = "🔥 Tempo di Spark!"
        content.body = "Non dimenticare di registrare i tuoi spark di oggi!"
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
        await scheduleNotification(
            type: .overloadReady,
            body: "Il tuo overload è pronto! Usalo per massimizzare i punti.",
            timeInterval: 5 // 5 seconds for testing, adjust as needed
        )
    }
    
    func scheduleWeeklyReport() async {
        // Schedule for Sunday at 18:00
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0
        
        await scheduleNotification(
            type: .weeklyReport,
            body: "Il tuo report settimanale è pronto! Scopri i tuoi progressi.",
            date: Calendar.current.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime),
            repeats: true
        )
    }
    
    func scheduleAchievementUnlocked(title: String, description: String) async {
        await scheduleNotification(
            type: .achievementUnlocked,
            body: "🎉 \(title): \(description)",
            timeInterval: 1
        )
    }
    
    func scheduleSparkSuggestion(category: SparkCategory) async {
        let suggestions = [
            "Hai provato a creare un spark \(category.displayName.lowercased()) oggi?",
            "Che ne dici di esplorare la categoria \(category.displayName)?",
            "Un piccolo spark \(category.displayName.lowercased()) può fare la differenza!",
            "È il momento perfetto per un spark di tipo \(category.displayName)!"
        ]
        
        let body = suggestions.randomElement() ?? "Tempo di creare un nuovo spark!"
        
        await scheduleNotification(
            type: .sparkSuggestion,
            body: body,
            timeInterval: TimeInterval.random(in: 3600...7200), // 1-2 hours
            userInfo: ["suggestedCategory": category.rawValue]
        )
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
        // Analyze user patterns and schedule intelligent reminders
        let lastSparkHour = userProfile.lastSparkDate.map { 
            Calendar.current.component(.hour, from: $0) 
        } ?? 19
        
        // Schedule daily reminder at user's preferred time
        await self.scheduleDailyReminder(at: lastSparkHour)
        
        // Schedule streak reminder if user has an active streak
        if userProfile.currentStreak > 0 {
            await self.scheduleStreakReminder()
        }
        
        // Schedule weekly report
        await self.scheduleWeeklyReport()
    }
    
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
}
