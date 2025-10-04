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
    
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
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
        }
    }
    
    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for route: SecondaryRoute) -> some View {
        switch route {
        case .settings:
            SettingsView()
        case .stats:
            StatsViewExpanded()
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
}

// MARK: - Preview
#Preview {
    MainTabView()
}
