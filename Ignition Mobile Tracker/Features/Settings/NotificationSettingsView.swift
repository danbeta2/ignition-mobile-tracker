//
//  NotificationSettingsView.swift
//  Ignition Mobile Tracker
//
//  Created by SASU TALHA Dev Team on 01/10/25.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = IgnitionNotificationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var dailyReminderEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var streakRemindersEnabled = true
    @State private var missionDeadlinesEnabled = true
    @State private var weeklyReportsEnabled = true
    
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Permission Status
                Section {
                    HStack {
                        Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Stato Notifiche")
                                .font(IgnitionFonts.body)
                            Text(notificationManager.isAuthorized ? "Autorizzate" : "Non Autorizzate")
                                .font(IgnitionFonts.caption2)
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        if !notificationManager.isAuthorized {
                            Button("Abilita") {
                                requestPermissions()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("Permessi")
                }
                
                // MARK: - Local Notifications
                Section {
                    // Daily Reminder
                    VStack(alignment: .leading, spacing: IgnitionSpacing.sm) {
                        Toggle("Daily Reminder", isOn: $dailyReminderEnabled)
                            .font(IgnitionFonts.body)
                        
                        if dailyReminderEnabled {
                            HStack {
                                Text("Time:")
                                    .font(IgnitionFonts.caption2)
                                    .foregroundColor(IgnitionColors.secondaryText)
                                
                                Spacer()
                                
                                DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .padding(.leading, IgnitionSpacing.md)
                        }
                    }
                    .onChange(of: dailyReminderEnabled) { _, enabled in
                        updateDailyReminder(enabled: enabled)
                    }
                    .onChange(of: dailyReminderTime) { _, _ in
                        if dailyReminderEnabled {
                            updateDailyReminder(enabled: true)
                        }
                    }
                    
                    Toggle("Streak Protection", isOn: $streakRemindersEnabled)
                        .font(IgnitionFonts.body)
                        .onChange(of: streakRemindersEnabled) { _, enabled in
                            updateStreakReminders(enabled: enabled)
                        }
                    
                    Toggle("Mission Deadlines", isOn: $missionDeadlinesEnabled)
                        .font(IgnitionFonts.body)
                        .onChange(of: missionDeadlinesEnabled) { _, enabled in
                            updateMissionDeadlines(enabled: enabled)
                        }
                    
                    Toggle("Weekly Reports", isOn: $weeklyReportsEnabled)
                        .font(IgnitionFonts.body)
                        .onChange(of: weeklyReportsEnabled) { _, enabled in
                            updateWeeklyReports(enabled: enabled)
                        }
                    
                } header: {
                    Text("Notifiche Locali")
                } footer: {
                    Text("Le notifiche locali vengono create direttamente sul tuo dispositivo.")
                        .font(IgnitionFonts.caption2)
                }
                
                // MARK: - Advanced Settings
                Section {
                    Button(action: {
                        Task {
                            await notificationManager.getPendingNotifications()
                        }
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Vedi Notifiche Programmate")
                            Spacer()
                            Text("\(notificationManager.pendingNotifications.count)")
                                .foregroundColor(IgnitionColors.secondaryText)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await notificationManager.cancelAllNotifications()
                            notificationManager.clearBadge()
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Cancella Tutte le Notifiche")
                                .foregroundColor(.red)
                        }
                    }
                    
                } header: {
                    Text("Gestione Avanzata")
                }
            }
            .navigationTitle("Notifiche")
            .navigationBarTitleDisplayMode(.large)
            .alert("Permessi Richiesti", isPresented: $showingPermissionAlert) {
                Button("Impostazioni") {
                    openAppSettings()
                }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Per ricevere notifiche, abilita i permessi nelle Impostazioni dell'app.")
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissions() {
        Task {
            let granted = await notificationManager.requestAuthorization()
            if !granted {
                showingPermissionAlert = true
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func loadSettings() {
        // Load saved settings from UserDefaults
        dailyReminderEnabled = UserDefaults.standard.bool(forKey: "dailyReminderEnabled")
        streakRemindersEnabled = UserDefaults.standard.bool(forKey: "streakRemindersEnabled")
        missionDeadlinesEnabled = UserDefaults.standard.bool(forKey: "missionDeadlinesEnabled")
        weeklyReportsEnabled = UserDefaults.standard.bool(forKey: "weeklyReportsEnabled")
        
        if let timeData = UserDefaults.standard.data(forKey: "dailyReminderTime"),
           let time = try? JSONDecoder().decode(Date.self, from: timeData) {
            dailyReminderTime = time
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(dailyReminderEnabled, forKey: "dailyReminderEnabled")
        UserDefaults.standard.set(streakRemindersEnabled, forKey: "streakRemindersEnabled")
        UserDefaults.standard.set(missionDeadlinesEnabled, forKey: "missionDeadlinesEnabled")
        UserDefaults.standard.set(weeklyReportsEnabled, forKey: "weeklyReportsEnabled")
        
        if let timeData = try? JSONEncoder().encode(dailyReminderTime) {
            UserDefaults.standard.set(timeData, forKey: "dailyReminderTime")
        }
    }
    
    // MARK: - Notification Updates
    
    private func updateDailyReminder(enabled: Bool) {
        Task {
            if enabled {
                let hour = Calendar.current.component(.hour, from: dailyReminderTime)
                let minute = Calendar.current.component(.minute, from: dailyReminderTime)
                await notificationManager.scheduleDailyReminder(at: hour, minute: minute)
            } else {
                await notificationManager.cancelNotifications(of: .dailyReminder)
            }
        }
        saveSettings()
    }
    
    private func updateStreakReminders(enabled: Bool) {
        Task {
            if enabled {
                await notificationManager.scheduleStreakReminder()
            } else {
                await notificationManager.cancelNotifications(of: .streakReminder)
            }
        }
        saveSettings()
    }
    
    private func updateMissionDeadlines(enabled: Bool) {
        Task {
            if !enabled {
                await notificationManager.cancelNotifications(of: NotificationType.missionDeadline)
            }
            // Mission deadline notifications are scheduled when missions are created
        }
        saveSettings()
    }
    
    private func updateWeeklyReports(enabled: Bool) {
        Task {
            if enabled {
                await notificationManager.scheduleWeeklyReport()
            } else {
                await notificationManager.cancelNotifications(of: .weeklyReport)
            }
        }
        saveSettings()
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(IgnitionNotificationManager.shared)
        .environmentObject(ThemeManager.shared)
}
