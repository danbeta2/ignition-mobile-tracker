//
//  Ignition_Mobile_TrackerApp.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 30/09/25.
//

import SwiftUI
import UserNotifications

@main
struct Ignition_Mobile_TrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var notificationManager = IgnitionNotificationManager.shared
    @StateObject private var pushNotificationService = PushNotificationService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(notificationManager)
                .environmentObject(pushNotificationService)
                .onAppear {
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        Task {
            // Request notification permissions
            await notificationManager.requestAuthorization()
            
            // Register for push notifications
            await pushNotificationService.registerForPushNotifications()
            
            // Schedule initial notifications
            let userProfile = persistenceController.getOrCreateUserProfile()
            await notificationManager.scheduleSmartReminders(based: userProfile)
            await pushNotificationService.scheduleIntelligentNotifications(for: userProfile)
        }
    }
}

// MARK: - App Delegate for Push Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure notification categories
        configureNotificationCategories()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationService.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            PushNotificationService.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        Task { @MainActor in
            PushNotificationService.shared.application(application, didReceiveRemoteNotification: userInfo)
        }
    }
    
    private func configureNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Quick Actions for Spark Creation
        let createSparkAction = UNNotificationAction(
            identifier: "CREATE_SPARK",
            title: "Create Spark",
            options: [.foreground]
        )
        
        let viewStatsAction = UNNotificationAction(
            identifier: "VIEW_STATS",
            title: "Vedi Stats",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Ignora",
            options: []
        )
        
        // Spark Reminder Category
        let sparkReminderCategory = UNNotificationCategory(
            identifier: "SPARK_REMINDER",
            actions: [createSparkAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Weekly Report Category
        let weeklyReportCategory = UNNotificationCategory(
            identifier: "WEEKLY_REPORT",
            actions: [viewStatsAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([sparkReminderCategory, weeklyReportCategory])
    }
}
