//
//  TabRouter.swift
//  Ignition Mobile Tracker
//
//  Created by Giulio Posa on 01/10/25.
//

import SwiftUI
import Combine

// MARK: - Tab Routes
enum TabRoute: String, CaseIterable {
    case home = "home"
    case tracker = "tracker"
    case library = "library"
    case missions = "missions"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .tracker: return "Tracker"
        case .library: return "Library"
        case .missions: return "Missions"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return AssetNames.TabIcons.home.systemName
        case .tracker: return AssetNames.TabIcons.tracker.systemName
        case .library: return "books.vertical.fill"
        case .missions: return AssetNames.TabIcons.missions.systemName
        }
    }
    
    var tag: Int {
        switch self {
        case .home: return 0
        case .tracker: return 1
        case .library: return 2
        case .missions: return 3
        }
    }
}

// MARK: - Secondary Routes
// Note: Stats and Settings are presented as sheets, not navigation routes
enum SecondaryRoute: String, CaseIterable {
    case achievements = "achievements"
    case collectibles = "collectibles"
    case sparkDetail = "spark_detail"
    case missionDetail = "mission_detail"
    case tableDetail = "table_detail"
    case entryDetail = "entry_detail"
    
    var title: String {
        switch self {
        case .achievements: return "Achievements"
        case .collectibles: return "Collections"
        case .sparkDetail: return "Spark Detail"
        case .missionDetail: return "Mission Detail"
        case .tableDetail: return "Table Detail"
        case .entryDetail: return "Entry Detail"
        }
    }
}

// MARK: - Tab Router
@MainActor
class TabRouter: ObservableObject {
    @Published var selectedTab: TabRoute = .home
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Tab Navigation
    func selectTab(_ tab: TabRoute) {
        selectedTab = tab
        AudioHapticsManager.shared.uiTapped()
    }
    
    // MARK: - Secondary Navigation
    func navigate(to route: SecondaryRoute, with data: Any? = nil) {
        navigationPath.append(route)
        AudioHapticsManager.shared.uiTapped()
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            AudioHapticsManager.shared.uiTapped()
        }
    }
    
    func navigateToRoot() {
        navigationPath = NavigationPath()
        AudioHapticsManager.shared.uiTapped()
    }
    
    // MARK: - Quick Actions
    @Published var shouldShowAddSpark = false
    
    func quickAddSpark() {
        selectedTab = .tracker
        shouldShowAddSpark = true
        AudioHapticsManager.shared.uiTapped()
    }
    
    func quickViewMissions() {
        selectedTab = .missions
        AudioHapticsManager.shared.uiTapped()
    }
}

// MARK: - Navigation Environment Key
struct TabRouterEnvironmentKey: EnvironmentKey {
    static let defaultValue = TabRouter()
}

extension EnvironmentValues {
    var tabRouter: TabRouter {
        get { self[TabRouterEnvironmentKey.self] }
        set { self[TabRouterEnvironmentKey.self] = newValue }
    }
}
