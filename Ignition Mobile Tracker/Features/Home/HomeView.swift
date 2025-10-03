//
//  HomeView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var sparkManager = SparkManager.shared
    @StateObject private var userProfileManager = UserProfileManager.shared
    @StateObject private var cardManager = CardManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @Environment(\.themeManager) private var themeManager
    @Environment(\.tabRouter) private var tabRouter
    
    @State private var showingOverloadEffects = false
    @State private var overloadAnimationScale: CGFloat = 1.0
    @State private var showingStats = false
    @State private var showingSettings = false
    @State private var selectedSparkForDetails: SparkModel?
    @State private var showingSparkDetail = false
    @State private var showingCardCollection = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header (Fixed at top)
            customHeaderBar
                .background(IgnitionColors.headerGray)
                .zIndex(10)
            
            // Main Content
            ScrollView {
                VStack(spacing: IgnitionSpacing.lg) {
                    // Hero Banner (Casino Style)
                    HeroBanner(onAction: {
                        tabRouter.quickAddSpark()
                    })
                    
                    // Quick Actions
                    quickActionsSection
                        .padding(.horizontal, IgnitionSpacing.md)
                    
                    // Ignition Core
                    ignitionCoreSection
                        .padding(.horizontal, IgnitionSpacing.md)
                    
                    // Spark Cards Collection
                    sparkCardsSection
                        .padding(.horizontal, IgnitionSpacing.md)
                    
                    Spacer(minLength: IgnitionSpacing.xl)
                }
                .padding(.top, IgnitionSpacing.sm)
            }
        }
        .background(themeManager.backgroundColor)
        .navigationBarHidden(true)
        .onAppear {
            setupNotificationObservers()
        }
        .overlay(
            overloadEffectsOverlay
                .opacity(showingOverloadEffects ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: showingOverloadEffects)
        )
        .sheet(isPresented: $showingStats) {
            StatsViewExpanded()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSparkDetail) {
            if let spark = selectedSparkForDetails {
                SparkDetailView(spark: spark)
            }
        }
        .sheet(isPresented: $showingCardCollection) {
            CardCollectionView()
        }
        .fullScreenCover(isPresented: $cardManager.showCardReveal) {
            if let card = cardManager.lastObtainedCard {
                CardRevealView(card: card, isPresented: $cardManager.showCardReveal)
            }
        }
    }
    
    // MARK: - Setup
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .showOverloadEffects,
            object: nil,
            queue: .main
        ) { _ in
            triggerOverloadEffects()
        }
    }
    
    // MARK: - Custom Header Bar (Casino Style - Fixed)
    private var customHeaderBar: some View {
        HStack {
            // Logo
            if let _ = UIImage(named: "app-logo") {
                Image("app-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 32)
                    .fireGlow(radius: 6, color: IgnitionColors.ignitionOrange)
            } else {
                Text("IGNITION")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .overlay(
                        LinearGradient(
                            colors: [IgnitionColors.ignitionOrange, IgnitionColors.fireRed],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text("IGNITION")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                        )
                    )
                    .fireGlow(radius: 6)
            }
            
            Spacer()
            
            HStack(spacing: IgnitionSpacing.sm) {
                // Stats Pill Button
                Button(action: {
                    showingStats = true
                    audioHapticsManager.uiTapped()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("STATS")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(IgnitionColors.ignitionOrange)
                            .fireGlow(radius: 4, color: IgnitionColors.ignitionOrange)
                    )
                }
                
                // Settings Pill Button
                Button(action: {
                    showingSettings = true
                    audioHapticsManager.uiTapped()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("SETTINGS")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(IgnitionColors.ignitionOrange)
                            .fireGlow(radius: 4, color: IgnitionColors.ignitionOrange)
                    )
                }
            }
        }
        .padding(.horizontal, IgnitionSpacing.md)
        .padding(.vertical, IgnitionSpacing.sm)
        .background(IgnitionColors.headerGray)
    }
    
    // MARK: - Header Section (Old - kept for reference)
    private var headerSection: some View {
        HStack {
            Spacer()
            
            // Stats Button
            Button(action: {
                showingStats = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.primaryColor)
            }
            
            // Settings Button
            Button(action: {
                showingSettings = true
                audioHapticsManager.uiTapped()
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(themeManager.primaryColor)
            }
        }
        .padding(.top, IgnitionSpacing.sm)
    }
    
    // MARK: - Ignition Core Section
    private var ignitionCoreSection: some View {
        VStack(spacing: IgnitionSpacing.md) {
            // Fuel Gauge
            fuelGaugeView
            
            // Stats Row
            statsRowView
        }
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.lg)
    }
    
    private var fuelGaugeView: some View {
        VStack(spacing: IgnitionSpacing.sm) {
            // Level Title with Icon
            let totalPoints = userProfileManager.userProfile?.totalSparkPoints ?? 0
            let levelInfo = IgnitionLevel.progress(for: totalPoints)
            
            HStack(spacing: IgnitionSpacing.xs) {
                Image(systemName: levelInfo.currentLevel.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(levelInfo.currentLevel.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(levelInfo.currentLevel.title)
                        .font(IgnitionFonts.title3)
                        .fontWeight(.bold)
                        .foregroundColor(levelInfo.currentLevel.color)
                    
                    Text("Level \(levelInfo.currentLevel.rawValue)")
                        .font(IgnitionFonts.caption1)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
            }
            
            // Progress Bar to Next Level
            if let nextLevel = levelInfo.nextLevel {
                VStack(spacing: IgnitionSpacing.xs) {
                    ProgressView(value: levelInfo.progressToNext)
                        .progressViewStyle(LinearProgressViewStyle(tint: levelInfo.currentLevel.color))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(levelInfo.pointsNeeded) points to \(nextLevel.title)")
                        .font(IgnitionFonts.caption2)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
            } else {
                Text("MAX LEVEL REACHED!")
                    .font(IgnitionFonts.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(IgnitionColors.goldAccent)
                    .goldGlow(radius: 4)
            }
        }
    }
    
    private var statsRowView: some View {
        HStack(spacing: IgnitionSpacing.lg) {
            let todaySparks = sparkManager.sparks(from: Calendar.current.startOfDay(for: Date()), to: Date()).count
            statItem(title: "Today", value: "\(todaySparks)", icon: "sparkles")
            
            Divider()
                .frame(height: 40)
                .background(IgnitionColors.mediumGray)
            
            let (currentStreak, _) = userProfileManager.getStreakInfo()
            statItem(title: "Streak", value: "\(currentStreak)", icon: "flame.fill")
            
            Divider()
                .frame(height: 40)
                .background(IgnitionColors.mediumGray)
            
            let (_, totalPoints, _) = userProfileManager.getTotalStats()
            statItem(title: "Points", value: formatNumber(totalPoints), icon: "star.fill")
        }
    }
    
    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: IgnitionSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.primaryColor)
            
            Text(value)
                .font(IgnitionFonts.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text(title)
                .font(IgnitionFonts.caption1)
                .foregroundColor(IgnitionColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            Text("Quick Actions")
                .font(IgnitionFonts.title3)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: IgnitionSpacing.md) {
                quickActionCard(
                    title: "Add Spark",
                    icon: AssetNames.SystemIcons.addButton.systemName,
                    color: themeManager.primaryColor
                ) {
                    audioHapticsManager.uiTapped()
                    tabRouter.quickAddSpark()
                }
                
                quickActionCard(
                    title: "Missions",
                    icon: AssetNames.TabIcons.missions.systemName,
                    color: IgnitionColors.success
                ) {
                    audioHapticsManager.uiTapped()
                    tabRouter.quickViewMissions()
                }
                
                quickActionCard(
                    title: "Library",
                    icon: "books.vertical.fill",
                    color: IgnitionColors.warning
                ) {
                    audioHapticsManager.uiTapped()
                    tabRouter.selectedTab = .library
                }
                
                quickActionCard(
                    title: "Stats",
                    icon: "chart.bar.fill",
                    color: .purple
                ) {
                    audioHapticsManager.uiTapped()
                    tabRouter.navigate(to: .stats)
                }
            }
        }
    }
    
    private func quickActionCard(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                // Background Image
                if let bgImage = backgroundImageName(for: title) {
                    Image(bgImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 130)
                        .clipped()
                        .opacity(0.3)
                }
                
                // Content Overlay
                VStack(spacing: IgnitionSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(color)
                        .fireGlow(radius: 8, color: color)
                    
                    Text(title)
                        .font(IgnitionFonts.callout)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                    .fill(themeManager.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                            .stroke(color.opacity(0.4), lineWidth: 1.5)
                    )
            )
            .cornerRadius(IgnitionRadius.lg)
            .shadow(color: IgnitionShadow.large, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func backgroundImageName(for title: String) -> String? {
        switch title {
        case "Add Spark": return "quick-tracker-bg"
        case "Library": return "quick-library-bg"
        case "Missions": return "quick-missions-bg"
        case "Stats": return "quick-stats-bg"
        default: return nil
        }
    }
    
    // MARK: - Spark Cards Section
    private var sparkCardsSection: some View {
        VStack(alignment: .leading, spacing: IgnitionSpacing.md) {
            HStack {
                HStack(spacing: IgnitionSpacing.xs) {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundColor(IgnitionColors.goldAccent)
                        .font(.system(size: 20))
                    
                    Text("Spark Cards")
                        .font(IgnitionFonts.title3)
                        .foregroundColor(themeManager.textColor)
                }
                
                Spacer()
                
                Button("View Collection") {
                    showingCardCollection = true
                    audioHapticsManager.uiTapped()
                }
                .font(IgnitionFonts.callout)
                .foregroundColor(themeManager.primaryColor)
            }
            
            // Collection stats and rarest cards
            VStack(spacing: IgnitionSpacing.md) {
                // Stats bar
                HStack(spacing: IgnitionSpacing.lg) {
                    // Total owned
                    VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                        Text("\(cardManager.ownedCardsCount)/50")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .goldGlow(radius: 4)
                        
                        Text("Cards Unlocked")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(IgnitionColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Progress circle
                    ZStack {
                        Circle()
                            .stroke(IgnitionColors.darkGray, lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: cardManager.completionPercentage)
                            .stroke(
                                AngularGradient(
                                    colors: [IgnitionColors.ignitionOrange, IgnitionColors.goldAccent, IgnitionColors.ignitionOrange],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(cardManager.completionPercentage * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // 3 Rarest cards
                if !cardManager.rarestOwnedCards.isEmpty {
                    HStack(spacing: IgnitionSpacing.sm) {
                        ForEach(cardManager.rarestOwnedCards, id: \.id) { card in
                            miniCardView(card)
                        }
                        
                        // Fill empty slots
                        ForEach(0..<(3 - cardManager.rarestOwnedCards.count), id: \.self) { _ in
                            emptyMiniCardView
                        }
                    }
                } else {
                    // All empty slots
                    HStack(spacing: IgnitionSpacing.sm) {
                        ForEach(0..<3, id: \.self) { _ in
                            emptyMiniCardView
                        }
                    }
                }
            }
            .padding(IgnitionSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                    .fill(themeManager.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [IgnitionColors.goldAccent.opacity(0.3), IgnitionColors.ignitionOrange.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: IgnitionShadow.large, radius: 10, x: 0, y: 5)
        }
    }
    
    private func miniCardView(_ card: SparkCardModel) -> some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: IgnitionRadius.sm)
                .fill(IgnitionColors.ignitionBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: IgnitionRadius.sm)
                        .stroke(card.rarity.color, lineWidth: 2)
                )
            
            // Card image or icon
            if let _ = UIImage(named: card.assetName) {
                Image(card.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 140)
                    .clipped()
                    .cornerRadius(IgnitionRadius.sm)
            } else {
                VStack(spacing: IgnitionSpacing.xs) {
                    Image(systemName: card.category.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(card.category.color)
                    
                    Text(card.displayTitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
            }
            
            // Rarity indicator
            VStack {
                HStack {
                    Spacer()
                    
                    Circle()
                        .fill(card.rarity.color)
                        .frame(width: 18, height: 18)
                        .padding(4)
                }
                
                Spacer()
            }
        }
        .frame(width: 100, height: 140)
        .shadow(color: card.rarity.glowColor, radius: 6, x: 0, y: 0)
    }
    
    private var emptyMiniCardView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: IgnitionRadius.sm)
                .fill(IgnitionColors.darkGray)
                .overlay(
                    RoundedRectangle(cornerRadius: IgnitionRadius.sm)
                        .stroke(IgnitionColors.mediumGray.opacity(0.3), lineWidth: 2)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                )
            
            Image(systemName: "questionmark")
                .font(.system(size: 30))
                .foregroundColor(IgnitionColors.mediumGray.opacity(0.5))
        }
        .frame(width: 100, height: 140)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: IgnitionSpacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(IgnitionColors.mediumGray)
            
            Text("No Sparks Yet")
                .font(IgnitionFonts.body)
                .foregroundColor(IgnitionColors.secondaryText)
            
            Text("Start by adding your first Spark!")
                .font(IgnitionFonts.callout)
                .foregroundColor(IgnitionColors.mediumGray)
                .multilineTextAlignment(.center)
            
            Button("Add Spark") {
                tabRouter.quickAddSpark()
            }
            .font(IgnitionFonts.callout)
            .fontWeight(.semibold)
            .foregroundColor(IgnitionColors.ignitionWhite)
            .padding(.horizontal, IgnitionSpacing.lg)
            .padding(.vertical, IgnitionSpacing.sm)
            .background(themeManager.primaryColor)
            .cornerRadius(IgnitionRadius.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(IgnitionSpacing.lg)
        .background(themeManager.cardColor)
        .cornerRadius(IgnitionRadius.md)
    }
    
    private func recentSparkCard(_ spark: SparkModel) -> some View {
        Button(action: {
            selectedSparkForDetails = spark
            showingSparkDetail = true
            audioHapticsManager.uiTapped()
        }) {
            HStack(spacing: IgnitionSpacing.md) {
                // Category Icon
                Image(systemName: spark.category.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.primaryColor)
                    .frame(width: 40, height: 40)
                    .fireGlow(radius: 4, color: themeManager.primaryColor)
                
                // Content
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text(spark.title)
                        .font(IgnitionFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(spark.category.displayName)
                        .font(IgnitionFonts.callout)
                        .foregroundColor(IgnitionColors.secondaryText)
                }
                
                Spacer()
                
                // Points
                VStack(alignment: .trailing, spacing: IgnitionSpacing.xs) {
                    Text("+\(spark.points)")
                        .font(IgnitionFonts.body)
                        .fontWeight(.heavy)
                        .foregroundColor(IgnitionColors.goldAccent)
                        .goldGlow(radius: 6)
                    
                    Text(timeAgo(from: spark.createdAt))
                        .font(IgnitionFonts.caption1)
                        .foregroundColor(IgnitionColors.mediumGray)
                }
            }
            .padding(IgnitionSpacing.lg)
            .frame(minHeight: 90)
            .background(
                RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                    .fill(themeManager.cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                            .stroke(IgnitionColors.ignitionOrange.opacity(0.3), lineWidth: 1.5)
                    )
            )
            .shadow(color: IgnitionShadow.large, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Overload Effects
    private var overloadEffectsOverlay: some View {
        ZStack {
            // Background flash
            Rectangle()
                .fill(IgnitionColors.warning.opacity(0.3))
                .ignoresSafeArea()
            
            // Particle effects (simplified)
            VStack {
                HStack {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundColor(IgnitionColors.warning)
                            .scaleEffect(overloadAnimationScale)
                    }
                }
                
                Text("OVERLOAD!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(IgnitionColors.warning)
                    .scaleEffect(overloadAnimationScale)
                
                Text("Energia al massimo!")
                    .font(.title2)
                    .foregroundColor(IgnitionColors.ignitionWhite)
            }
        }
    }
    
    private func triggerOverloadEffects() {
        showingOverloadEffects = true
        overloadAnimationScale = 1.2
        
        // Hide effects after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingOverloadEffects = false
            overloadAnimationScale = 1.0
        }
    }
    
    // MARK: - Helper Methods
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environment(\.themeManager, ThemeManager.shared)
        .environment(\.tabRouter, TabRouter())
}
