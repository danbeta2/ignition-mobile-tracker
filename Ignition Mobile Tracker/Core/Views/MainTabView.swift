//
//  MainTabView.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var audioHapticsManager = AudioHapticsManager.shared
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var cardManager = CardManager.shared
    
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    // Mission completion toast
    @State private var completedMissions: [IgnitionMissionModel] = []
    @State private var showingMissionToast = false
    @State private var currentToastMission: IgnitionMissionModel?
    
    var body: some View {
        NavigationStack(path: $tabRouter.navigationPath) {
            TabView(selection: $tabRouter.selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: TabRoute.home.iconName)
                    Text(TabRoute.home.title)
                }
                .tag(TabRoute.home)
                .environmentObject(themeManager)
                .environmentObject(audioHapticsManager)
            
            // Tracker Tab
            TrackerViewExpanded()
                .tabItem {
                    Image(systemName: TabRoute.tracker.iconName)
                    Text(TabRoute.tracker.title)
                }
                .tag(TabRoute.tracker)
                .environmentObject(themeManager)
                .environmentObject(audioHapticsManager)
            
            // Library Tab
            LibraryView()
                .tabItem {
                    Image(systemName: TabRoute.library.iconName)
                    Text(TabRoute.library.title)
                }
                .tag(TabRoute.library)
                .environmentObject(themeManager)
                .environmentObject(audioHapticsManager)
            
            // Missions Tab
            MissionsView()
                .tabItem {
                    Image(systemName: TabRoute.missions.iconName)
                    Text(TabRoute.missions.title)
                }
                .tag(TabRoute.missions)
                .environmentObject(themeManager)
                .environmentObject(audioHapticsManager)
            
            }
            .accentColor(themeManager.primaryColor)
            .environment(\.tabRouter, tabRouter)
            .environment(\.themeManager, themeManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                setupTabBarAppearance()
                setupMissionCompletionObserver()
            }
            .onChange(of: cardManager.showCardReveal) { oldValue, newValue in
                // When card reveal closes, show pending mission toasts
                if oldValue == true && newValue == false {
                    print("🎴 Card reveal closed, checking for pending mission toasts...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showNextMissionToast()
                    }
                }
            }
            .navigationDestination(for: SecondaryRoute.self) { route in
                destinationView(for: route)
            }
            .alert(errorManager.currentError?.title ?? "Error", isPresented: $errorManager.showAlert) {
                Button("OK") {
                    errorManager.currentError = nil
                }
            } message: {
                Text(errorManager.currentError?.message ?? "An unexpected error occurred.")
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .overlay(
                Group {
                    if showingMissionToast, let mission = currentToastMission {
                        missionCompletionToast(mission: mission)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(999)
                    }
                }
            )
        }
    }
    
    // MARK: - Navigation Destinations
    // Note: Stats and Settings are presented as sheets, not navigation destinations
    @ViewBuilder
    private func destinationView(for route: SecondaryRoute) -> some View {
        switch route {
        case .achievements:
            AchievementsView()
        case .collectibles:
            Text("Collectibles View")
                .navigationTitle("Collectibles")
        case .sparkDetail:
            Text("Spark Detail View")
                .navigationTitle("Spark Detail")
        case .missionDetail:
            Text("Mission Detail View")
                .navigationTitle("Mission Detail")
        case .tableDetail:
            Text("Table Detail View")
                .navigationTitle("Table Detail")
        case .entryDetail:
            Text("Entry Detail View")
                .navigationTitle("Entry Detail")
        }
    }
    
    // MARK: - Tab Bar Appearance Setup
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // Configure background
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(themeManager.backgroundColor)
        
        // Configure item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(IgnitionColors.mediumGray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(IgnitionColors.mediumGray)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(themeManager.primaryColor)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(themeManager.primaryColor)
        ]
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Mission Completion Observer
    private func setupMissionCompletionObserver() {
        NotificationCenter.default.addObserver(
            forName: .missionCompleted,
            object: nil,
            queue: .main
        ) { notification in
            if let mission = notification.object as? IgnitionMissionModel {
                // Add to queue
                completedMissions.append(mission)
                
                // If card reveal is showing, wait for it to close
                // Otherwise, show toast immediately
                if !cardManager.showCardReveal && !showingMissionToast {
                    showNextMissionToast()
                }
            }
        }
    }
    
    private func showNextMissionToast() {
        // Don't show toast if card reveal is active
        guard !cardManager.showCardReveal else {
            print("⏸️ Toast paused: card reveal is active")
            return
        }
        
        guard !completedMissions.isEmpty, !showingMissionToast else { return }
        
        // Get next mission from queue
        currentToastMission = completedMissions.removeFirst()
        
        print("🎉 Showing mission completion toast: \(currentToastMission?.title ?? "")")
        
        // Show toast with animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showingMissionToast = true
        }
        
        // Auto-dismiss after 5 seconds (increased for better visibility)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showingMissionToast = false
            }
            
            // Show next toast if any in queue
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showNextMissionToast()
            }
        }
    }
    
    // MARK: - Mission Completion Toast
    @ViewBuilder
    private func missionCompletionToast(mission: IgnitionMissionModel) -> some View {
        VStack {
            HStack(spacing: IgnitionSpacing.md) {
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(IgnitionColors.goldAccent.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundColor(IgnitionColors.goldAccent)
                        .goldGlow(radius: 8)
                }
                
                // Content
                VStack(alignment: .leading, spacing: IgnitionSpacing.xs) {
                    Text("Mission Completed!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(mission.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(IgnitionColors.secondaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: IgnitionSpacing.xs) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(IgnitionColors.ignitionOrange)
                        
                        Text("+\(mission.rewardPoints) POINTS")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(IgnitionColors.goldAccent)
                            .goldGlow(radius: 4)
                    }
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showingMissionToast = false
                    }
                    
                    // Show next toast if any
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showNextMissionToast()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(IgnitionColors.mediumGray)
                }
            }
            .padding(IgnitionSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                    .fill(IgnitionColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: IgnitionRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [IgnitionColors.goldAccent.opacity(0.6), IgnitionColors.ignitionOrange.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, IgnitionSpacing.md)
            .padding(.top, 60) // Below status bar
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
