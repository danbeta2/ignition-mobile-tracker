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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                    initializeCardCollection()
                }
        }
    }
    
    private func setupNotifications() {
        Task {
            // Request notification permissions for local notifications only
            await notificationManager.requestAuthorization()
            
            // Schedule local notifications
            let userProfile = persistenceController.getOrCreateUserProfile()
            await notificationManager.scheduleSmartReminders(based: userProfile)
        }
    }
    
    private func initializeCardCollection() {
        Task {
            await MainActor.run {
                CardManager.shared.initializeCardCollection()
            }
        }
    }
}

// MARK: - App Delegate for Local Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure notification categories for local notifications
        configureNotificationCategories()
        
        return true
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
