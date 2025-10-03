//
//  HomeViewExpanded.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import Charts

struct HomeViewExpanded: View {
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var missionManager = MissionManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    // MARK: - State Variables
    @State private var showingOverloadEffects = false
    @State private var overloadAnimationScale: CGFloat = 1.0
    @State private var showingSettings = false
    @State private var showingNotifications = false
    @State private var showingQuickAdd = false
    @State private var showingStreakDetails = false
    @State private var showingFuelDetails = false
    @State private var showingInsights = false
    @State private var showingAchievements = false
    @State private var selectedTimeRange: TimeRange = .today
    @State private var animateStats = false
    @State private var refreshing = false
    @State private var showingTips = false
    @State private var currentTipIndex = 0
    
    // MARK: - Computed Properties
    private var todaysSparks: [SparkModel] {
        let calendar = Calendar.current
        let today = Date()
        return sparkManager.sparks.filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
    }
    
    private var weeklyProgress: Double {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekSparks = sparkManager.sparks.filter { $0.createdAt >= startOfWeek }
        return min(Double(weekSparks.count) / 20.0, 1.0) // Target: 20 sparks per week
    }
    
    private var currentStreak: Int {
        userProfileManager.getStreakInfo().current
    }
    
    private var longestStreak: Int {
        userProfileManager.getStreakInfo().longest
    }
    
    private var totalPoints: Int {
        userProfileManager.getTotalStats().points
    }
    
    private var currentLevel: Int {
        totalPoints / 1000 + 1
    }
    
    private var progressToNextLevel: Double {
        Double(totalPoints % 1000) / 1000.0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: IgnitionSpacing.lg) {
                    // Enhanced Header with Profile & Notifications
                    enhancedHeaderSection
                    
                    // Daily Summary Card
                    dailySummaryCard
                    
                    // Enhanced Ignition Core with Animations
                    enhancedIgnitionCoreSection
                    
                    // Level & Progress System
                    levelProgressSection
                    
                    // Weekly Challenge Progress
                    weeklyChallengeSection
                    
                    // Quick Actions Grid (Expanded)
                    expandedQuickActionsSection
                    
                    // Live Insights & Tips
                    liveInsightsSection
                    
                    // Recent Activity with Rich Details
                    enhancedRecentActivitySection
                    
                    // Achievements Preview
                    achievementsPreviewSection
                    
                    // Motivational Quote/Tip
                    motivationalSection
                    
                    Spacer(minLength: IgnitionSpacing.xl)
                }
                .padding(.horizontal, IgnitionSpacing.md)
                .refreshable {
                    await refreshData()
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Ignition")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: IgnitionSpacing.sm) {
                        notificationsButton
                        settingsButton
                    }
                }
            }
            .onAppear {
                setupNotificationObservers()
                animateStatsOnAppear()
            }
            .overlay(
                overloadEffectsOverlay
                    .opacity(showingOverloadEffects ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: showingOverloadEffects)
            )
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddSparkView()
            }
            .sheet(isPresented: $showingStreakDetails) {
                StreakDetailsView()
            }
            .sheet(isPresented: $showingFuelDetails) {
                FuelDetailsView()
            }
            .sheet(isPresented: $showingInsights) {
                InsightsView()
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView()
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    private var enhancedHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(greetingMessage)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                if let displayName = userProfileManager.userProfile?.displayName {
                    Text(displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                } else {
                    Text("Igniter")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                Text(currentDateString)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Weather & Time Info
            VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                Text(currentTimeString)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                HStack(spacing: IgnitionSpacing.xs) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("22°C")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.vertical, IgnitionSpacing.sm)
    }
    
    // MARK: - Daily Summary Card
    private var dailySummaryCard: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Oggi")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("\(todaysSparks.count) Spark creati")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                // Daily Goal Progress
                ZStack {
                    Circle()
                        .stroke(themeManager.secondaryColor.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: min(Double(todaysSparks.count) / 5.0, 1.0))
                        .stroke(themeManager.primaryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: todaysSparks.count)
                    
                    Text("\(todaysSparks.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                }
            }
            
            // Today's Categories Breakdown
            if !todaysSparks.isEmpty {
                HStack(spacing: IgnitionSpacing.sm) {
                    ForEach(SparkCategory.allCases, id: \.self) { category in
                        let count = todaysSparks.filter { $0.category == category }.count
                        if count > 0 {
                            VStack(spacing: IgnitionSpacing.xs) {
                                Image(systemName: AssetNames.SparkCategories.allCases.first(where: { $0.displayName.lowercased().contains(category.rawValue) })?.systemName ?? "circle.fill")
                                    .foregroundColor(themeManager.primaryColor)
                                    .font(.caption)
                                
                                Text("\(count)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            .padding(.horizontal, IgnitionSpacing.xs)
                            .padding(.vertical, IgnitionSpacing.xs)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(IgnitionCornerRadius.sm)
                        }
                    }
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Enhanced Ignition Core Section
    private var enhancedIgnitionCoreSection: some View {
        VStack(spacing: IgnitionSpacing.lg) {
            // Core Header
            HStack {
                Text("Ignition Core")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingFuelDetails = true
                    audioHapticsManager.uiTapped()
                }) {
                    Image(systemName: AssetNames.SystemIcons.infoIcon.systemName)
                        .foregroundColor(themeManager.primaryColor)
                        .font(.title3)
                }
            }
            
            // Enhanced Fuel Gauge with Animations
            enhancedFuelGaugeView
            
            // Core Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: IgnitionSpacing.md) {
                coreStatCard(
                    title: "Streak",
                    value: "\(currentStreak)",
                    subtitle: "giorni",
                    icon: AssetNames.SystemIcons.streakIcon.systemName,
                    color: .orange,
                    action: { showingStreakDetails = true }
                )
                
                coreStatCard(
                    title: "Punti",
                    value: formatNumber(totalPoints),
                    subtitle: "totali",
                    icon: AssetNames.SystemIcons.pointsIcon.systemName,
                    color: .yellow,
                    action: { showingInsights = true }
                )
                
                coreStatCard(
                    title: "Livello",
                    value: "\(currentLevel)",
                    subtitle: "attuale",
                    icon: "star.circle.fill",
                    color: .purple,
                    action: { showingAchievements = true }
                )
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
        .shadow(color: themeManager.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Enhanced Fuel Gauge
    private var enhancedFuelGaugeView: some View {
        VStack(spacing: IgnitionSpacing.md) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(themeManager.secondaryColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // Fuel Level Circle
                Circle()
                    .trim(from: 0, to: userProfileManager.getCurrentFuelPercentage())
                    .stroke(
                        LinearGradient(
                            colors: fuelGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: userProfileManager.getCurrentFuelPercentage())
                
                // Overload Effect
                if userProfileManager.isInOverloadMode() {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 170, height: 170)
                        .scaleEffect(overloadAnimationScale)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: overloadAnimationScale)
                }
                
                // Center Content
                VStack(spacing: IgnitionSpacing.xs) {
                    if userProfileManager.isInOverloadMode() {
                        Image(systemName: AssetNames.SystemIcons.overloadIcon.systemName)
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                        
                        Text("OVERLOAD")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                    } else {
                        Text("\(Int(userProfileManager.getCurrentFuelPercentage() * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Fuel Level")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            
            // Fuel Status Text
            Text(fuelStatusText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(fuelStatusColor)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Level Progress Section
    private var levelProgressSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                Text("Livello \(currentLevel)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Text("\(totalPoints % 1000)/1000 XP")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeManager.secondaryColor.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressToNextLevel, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 1), value: progressToNextLevel)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Livello \(currentLevel)")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Text("Livello \(currentLevel + 1)")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
    }
    
    // MARK: - Weekly Challenge Section
    private var weeklyChallengeSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Sfida Settimanale")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("20 Spark questa settimana")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: weeklyProgress,
                    size: 50,
                    lineWidth: 4,
                    color: .green
                )
            }
            
            // Progress Details
            HStack {
                Text("\(Int(weeklyProgress * 20))/20 completati")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Text("\(Int((1 - weeklyProgress) * 20)) rimanenti")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
    }
    
    // MARK: - Expanded Quick Actions
    private var expandedQuickActionsSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: IgnitionSpacing.md) {
                quickActionButton(
                    title: "New Spark",
                    icon: AssetNames.SystemIcons.addButton.systemName,
                    color: themeManager.primaryColor,
                    action: {
                        showingQuickAdd = true
                        audioHapticsManager.uiTapped()
                    }
                )
                
                quickActionButton(
                    title: "Tracker",
                    icon: AssetNames.TabIcons.tracker.systemName,
                    color: .blue,
                    action: {
                        tabRouter.selectedTab = .tracker
                        audioHapticsManager.uiTapped()
                    }
                )
                
                quickActionButton(
                    title: "Missions",
                    icon: AssetNames.TabIcons.missions.systemName,
                    color: .orange,
                    action: {
                        tabRouter.selectedTab = .missions
                        audioHapticsManager.uiTapped()
                    }
                )
                
                quickActionButton(
                    title: "Stats",
                    icon: "chart.bar.fill",
                    color: .purple,
                    action: {
                        tabRouter.navigate(to: .stats)
                        audioHapticsManager.uiTapped()
                    }
                )
                
                quickActionButton(
                    title: "Insights",
                    icon: AssetNames.ChartIcons.analytics.systemName,
                    color: .purple,
                    action: {
                        showingInsights = true
                        audioHapticsManager.uiTapped()
                    }
                )
                
                quickActionButton(
                    title: "Library",
                    icon: "books.vertical.fill",
                    color: .yellow,
                    action: {
                        tabRouter.selectedTab = .library
                        audioHapticsManager.uiTapped()
                    }
                )
                
                quickActionButton(
                    title: "Settings",
                    icon: AssetNames.SystemIcons.settingsIcon.systemName,
                    color: .gray,
                    action: {
                        showingSettings = true
                        audioHapticsManager.uiTapped()
                    }
                )
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    // MARK: - Live Insights Section
    private var liveInsightsSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                Text("Insights Live")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button("Vedi Tutto") {
                    showingInsights = true
                    audioHapticsManager.uiTapped()
                }
                .font(.caption)
                .foregroundColor(themeManager.primaryColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.md) {
                    insightCard(
                        title: "Categoria Preferita",
                        value: mostUsedCategory,
                        icon: "chart.pie.fill",
                        color: .blue
                    )
                    
                    insightCard(
                        title: "Orario Migliore",
                        value: bestTimeOfDay,
                        icon: "clock.fill",
                        color: .orange
                    )
                    
                    insightCard(
                        title: "Streak Record",
                        value: "\(longestStreak) giorni",
                        icon: "flame.fill",
                        color: .red
                    )
                    
                    insightCard(
                        title: "Media Giornaliera",
                        value: String(format: "%.1f", dailyAverage),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
        .padding(.vertical, IgnitionSpacing.md)
    }
    
    // MARK: - Enhanced Recent Activity
    private var enhancedRecentActivitySection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                Text("Attività Recente")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button("Vedi Tutto") {
                    tabRouter.selectedTab = .tracker
                    audioHapticsManager.uiTapped()
                }
                .font(.caption)
                .foregroundColor(themeManager.primaryColor)
            }
            
            if sparkManager.sparks.isEmpty {
                emptyActivityView
            } else {
                LazyVStack(spacing: IgnitionSpacing.sm) {
                    ForEach(Array(sparkManager.sparks.prefix(5).enumerated()), id: \.element.id) { index, spark in
                        enhancedSparkRow(spark: spark, index: index)
                    }
                }
            }
        }
        .padding(IgnitionSpacing.md)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.lg)
    }
    
    // MARK: - Achievements Preview
    private var achievementsPreviewSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                Text("Obiettivi")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button("Vedi Tutto") {
                    showingAchievements = true
                    audioHapticsManager.uiTapped()
                }
                .font(.caption)
                .foregroundColor(themeManager.primaryColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: IgnitionSpacing.md) {
                    achievementBadge(
                        title: "Prima Scintilla",
                        description: "Crea il tuo primo Spark",
                        icon: "sparkles",
                        isUnlocked: !sparkManager.sparks.isEmpty,
                        progress: sparkManager.sparks.isEmpty ? 0 : 1
                    )
                    
                    achievementBadge(
                        title: "Streak Master",
                        description: "Mantieni uno streak di 7 giorni",
                        icon: "flame.fill",
                        isUnlocked: currentStreak >= 7,
                        progress: min(Double(currentStreak) / 7.0, 1.0)
                    )
                    
                    achievementBadge(
                        title: "Punto di Svolta",
                        description: "Raggiungi 1000 punti",
                        icon: "star.fill",
                        isUnlocked: totalPoints >= 1000,
                        progress: min(Double(totalPoints) / 1000.0, 1.0)
                    )
                    
                    achievementBadge(
                        title: "Esploratore",
                        description: "Usa tutte le categorie",
                        icon: "map.fill",
                        isUnlocked: hasUsedAllCategories,
                        progress: categoryUsageProgress
                    )
                }
                .padding(.horizontal, IgnitionSpacing.md)
            }
        }
        .padding(.vertical, IgnitionSpacing.md)
    }
    
    // MARK: - Motivational Section
    private var motivationalSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Consiglio del Giorno")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(dailyTip)
                        .font(.body)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            Button(action: {
                generateNewTip()
                audioHapticsManager.uiTapped()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Nuovo Consiglio")
                }
                .font(.caption)
                .foregroundColor(themeManager.primaryColor)
            }
        }
        .padding(IgnitionSpacing.md)
        .background(
            LinearGradient(
                colors: [themeManager.primaryColor.opacity(0.1), themeManager.secondaryColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(IgnitionCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: IgnitionCornerRadius.lg)
                .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Views and Methods
    
    private func coreStatCard(title: String, value: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, IgnitionSpacing.sm)
            .background(themeManager.backgroundColor)
            .cornerRadius(IgnitionCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(themeManager.backgroundColor)
            .cornerRadius(IgnitionCornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func insightCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: IgnitionSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120, height: 80)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
    }
    
    private func enhancedSparkRow(spark: SparkModel, index: Int) -> some View {
        HStack(spacing: IgnitionSpacing.md) {
            // Category Icon
            Image(systemName: AssetNames.SparkCategories.allCases.first(where: { $0.displayName.lowercased().contains(spark.category.rawValue) })?.systemName ?? "circle.fill")
                .foregroundColor(themeManager.primaryColor)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                Text(spark.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(1)
                
                HStack(spacing: IgnitionSpacing.sm) {
                    Text(spark.category.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, IgnitionSpacing.xs)
                        .padding(.vertical, 2)
                        .background(themeManager.primaryColor.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text(timeAgoString(from: spark.createdAt))
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                HStack(spacing: 2) {
                    ForEach(0..<spark.intensity.rawValue, id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Text("+\(spark.points)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, IgnitionSpacing.sm)
        .background(themeManager.backgroundColor)
        .cornerRadius(IgnitionCornerRadius.sm)
        .opacity(animateStats ? 1 : 0)
        .offset(x: animateStats ? 0 : 50)
        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: animateStats)
    }
    
    private func achievementBadge(title: String, description: String, icon: String, isUnlocked: Bool, progress: Double) -> some View {
        VStack(spacing: IgnitionSpacing.sm) {
            ZStack {
                if isUnlocked {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                }
                
                if !isUnlocked {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(themeManager.primaryColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            VStack(spacing: IgnitionSpacing.xs) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if !isUnlocked {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryColor)
            }
        }
        .frame(width: 100)
        .padding(.vertical, IgnitionSpacing.sm)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(IgnitionCornerRadius.md)
        .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
    }
    
    private var emptyActivityView: some View {
        VStack(spacing: IgnitionSpacing.md) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("Nessuna attività recente")
                .font(.headline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("Inizia creando il tuo primo Spark!")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Create Spark") {
                showingQuickAdd = true
                audioHapticsManager.uiTapped()
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.primaryColor)
        }
        .padding(.vertical, IgnitionSpacing.xl)
    }
    
    // MARK: - Toolbar Buttons
    
    private var notificationsButton: some View {
        Button(action: {
            showingNotifications = true
            audioHapticsManager.uiTapped()
        }) {
            ZStack {
                Image(systemName: AssetNames.SystemIcons.notificationIcon.systemName)
                    .foregroundColor(themeManager.primaryColor)
                    .font(.title3)
                
                // Notification Badge
                if hasUnreadNotifications {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettings = true
            audioHapticsManager.uiTapped()
        }) {
            Image(systemName: AssetNames.SystemIcons.settingsIcon.systemName)
                .foregroundColor(themeManager.primaryColor)
                .font(.title3)
        }
    }
    
    // MARK: - Computed Properties for Data
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Buongiorno"
        case 12..<17: return "Buon pomeriggio"
        case 17..<22: return "Buonasera"
        default: return "Buonanotte"
        }
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: Date())
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private var fuelGradientColors: [Color] {
        let percentage = userProfileManager.getCurrentFuelPercentage()
        if percentage < 0.3 {
            return [.red, .orange]
        } else if percentage < 0.7 {
            return [.orange, .yellow]
        } else {
            return [.green, .blue]
        }
    }
    
    private var fuelStatusText: String {
        let percentage = userProfileManager.getCurrentFuelPercentage()
        if userProfileManager.isInOverloadMode() {
            return "Modalità Overload Attiva! 🔥"
        } else if percentage < 0.3 {
            return "Livello carburante basso. Crea più Spark!"
        } else if percentage < 0.7 {
            return "Buon livello di energia. Continua così!"
        } else {
            return "Energia al massimo! Sei in fiamme! 🔥"
        }
    }
    
    private var fuelStatusColor: Color {
        let percentage = userProfileManager.getCurrentFuelPercentage()
        if userProfileManager.isInOverloadMode() {
            return .white
        } else if percentage < 0.3 {
            return .red
        } else if percentage < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var mostUsedCategory: String {
        let categoryCount = Dictionary(grouping: sparkManager.sparks, by: { $0.category })
            .mapValues { $0.count }
        
        guard let mostUsed = categoryCount.max(by: { $0.value < $1.value }) else {
            return "Nessuna"
        }
        
        return mostUsed.key.rawValue.capitalized
    }
    
    private var bestTimeOfDay: String {
        let hourCount = Dictionary(grouping: sparkManager.sparks, by: { Calendar.current.component(.hour, from: $0.createdAt) })
            .mapValues { $0.count }
        
        guard let bestHour = hourCount.max(by: { $0.value < $1.value }) else {
            return "N/A"
        }
        
        return "\(bestHour.key):00"
    }
    
    private var dailyAverage: Double {
        guard !sparkManager.sparks.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let dates = Set(sparkManager.sparks.map { calendar.startOfDay(for: $0.createdAt) })
        let dayCount = dates.count
        
        return Double(sparkManager.sparks.count) / Double(dayCount)
    }
    
    private var hasUsedAllCategories: Bool {
        let usedCategories = Set(sparkManager.sparks.map { $0.category })
        return usedCategories.count == SparkCategory.allCases.count
    }
    
    private var categoryUsageProgress: Double {
        let usedCategories = Set(sparkManager.sparks.map { $0.category })
        return Double(usedCategories.count) / Double(SparkCategory.allCases.count)
    }
    
    private var hasUnreadNotifications: Bool {
        // Placeholder logic - implement based on notification system
        return false
    }
    
    private var dailyTip: String {
        let tips = [
            "Inizia la giornata con un piccolo Spark per dare il tono positivo!",
            "Le decisioni prese al mattino tendono ad essere più efficaci.",
            "Prova a sperimentare qualcosa di nuovo oggi, anche se piccolo.",
            "Rifletti sui tuoi progressi: ogni Spark conta!",
            "Le sfide più difficili spesso portano ai risultati migliori.",
            "Mantieni la costanza: piccoli passi quotidiani fanno grandi differenze.",
            "Celebra i piccoli successi lungo il percorso!",
            "L'energia cresce con l'azione: più Spark crei, più energia avrai.",
            "Condividi i tuoi progressi con qualcuno che ti supporta.",
            "Ricorda: ogni esperto è stato una volta un principiante."
        ]
        
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return tips[dayOfYear % tips.count]
    }
    
    // MARK: - Helper Methods
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .overloadTriggered,
            object: nil,
            queue: .main
        ) { _ in
            triggerOverloadEffects()
        }
    }
    
    private func triggerOverloadEffects() {
        showingOverloadEffects = true
        overloadAnimationScale = 1.2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showingOverloadEffects = false
            overloadAnimationScale = 1.0
        }
    }
    
    private func animateStatsOnAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateStats = true
        }
    }
    
    private func generateNewTip() {
        currentTipIndex = (currentTipIndex + 1) % 10
    }
    
    private func refreshData() async {
        refreshing = true
        
        // Simulate data refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            sparkManager.loadSparks()
            userProfileManager.loadUserProfile()
            missionManager.loadMissions()
            refreshing = false
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Overload Effects Overlay
    private var overloadEffectsOverlay: some View {
        ZStack {
            // Background overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.3)],
                        center: .center,
                        startRadius: 100,
                        endRadius: 300
                    )
                )
                .ignoresSafeArea()
            
            // Animated particles effect
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: IgnitionSpacing.lg) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow, radius: 10)
                            .scaleEffect(overloadAnimationScale)
                        
                        Text("OVERLOAD MODE!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                        
                        Text("Energia al massimo! 🔥")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views
struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Placeholder Views for Sheets

struct NotificationsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Notifiche")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrate le notifiche")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Notifiche")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QuickAddSparkView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Aggiungi Spark Veloce")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verrà implementata l'aggiunta rapida di Spark")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Nuovo Spark")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StreakDetailsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Dettagli Streak")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati i dettagli dello streak")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Streak")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FuelDetailsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Dettagli Carburante")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati i dettagli del carburante")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Fuel Level")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InsightsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Insights Avanzati")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati insights dettagliati")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AchievementsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Obiettivi e Traguardi")
                    .font(.largeTitle)
                    .padding()
                
                Text("Qui verranno mostrati tutti gli obiettivi")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Obiettivi")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Time Range Enum
enum TimeRange: String, CaseIterable {
    case today = "Oggi"
    case week = "Settimana"
    case month = "Mese"
    case year = "Anno"
}

#Preview {
    HomeViewExpanded()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
